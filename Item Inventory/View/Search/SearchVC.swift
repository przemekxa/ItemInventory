//
//  SearchVC.swift
//  Item Inventory
//
//  Created by Air on 07/05/2021.
//

import UIKit
import CoreData

class SearchVC: UIViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {
    
    private var collectionView: UICollectionView!
    
    unowned private var storage: Storage!
    
    private var resultsController: NSFetchedResultsController<Item>!

    private var searchController: UISearchController!
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>!
    
    init(_ storage: Storage) {
        self.storage = storage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Items"

        // Configure the layout
        configureLayout()
        
        // Make the data source
        dataSource = makeDataSource()
        
        // Make the fetch results controller
        makeFetchResultsController()

        // Make teh search controller
        makeSearchController()

        navigationController?.navigationBar.sizeToFit()

    }
    
    /// Configure the layout
    private func configureLayout() {
        
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        // Create collection view with list layout
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 0.0),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0.0),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0.0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0),
        ])
        
        
        print("Layout configured")
    }
    
    
    /// Create a cell registration
    private func cellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, Item>{
        .init { cell, indexPath, item in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.name ?? "Unknown name"
            cell.contentConfiguration = configuration
        }
    }
    
    
    /// Make data source
    private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, NSManagedObjectID> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, objectID in
            guard let item = try? self.storage.context.existingObject(with: objectID) as? Item else {
                fatalError("Managed object is not available")
            }
            return collectionView
                .dequeueConfiguredReusableCell(using: self.cellRegistration(),
                                               for: indexPath,
                                               item: item)
        }
    }
    
    private func makeFetchResultsController() {
        // Create fetch request
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.name, ascending: true)]
        resultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: storage.context,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        
        resultsController.delegate = self
        
        try? resultsController.performFetch()
    }


    /// Make the search controller
    private func makeSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for an item"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {

        var snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

        let currentSnapshot = dataSource.snapshot() as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { identifier in
            if
                let currentIndex = currentSnapshot.indexOfItem(identifier),
                let index = snapshot.indexOfItem(identifier),
                index == currentIndex,
                let existingObject = try? controller.managedObjectContext.existingObject(with: identifier),
                existingObject.isUpdated {
                return identifier
            }
            return nil
        }

        snapshot.reloadItems(reloadIdentifiers)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // Handle search results
    func updateSearchResults(for searchController: UISearchController) {

        // TODO: Make search smarter

        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            let newPredicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
            if resultsController.fetchRequest.predicate != newPredicate {
                resultsController.fetchRequest.predicate = newPredicate
                try? resultsController.performFetch()
            }
        } else {
            if resultsController.fetchRequest.predicate != nil {
                resultsController.fetchRequest.predicate = nil
                try? resultsController.performFetch()
            }
        }


        print("Searched term:", searchController.searchBar.text as Any)
    }

}
