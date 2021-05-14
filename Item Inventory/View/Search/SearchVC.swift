//
//  SearchVC.swift
//  Item Inventory
//
//  Created by Air on 07/05/2021.
//

import UIKit
import CoreData
import SwiftUI

class SearchVC: UIViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UICollectionViewDelegate {
    
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

    // MARK: - Collection View

    /// Configure the layout
    private func configureLayout() {

        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 64.0, right: 0.0)
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.backgroundColor = .systemGroupedBackground

        view.addSubview(collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        // Present the item details
        if
            let objectID = dataSource.itemIdentifier(for: indexPath),
            let item = try? storage.context.existingObject(with: objectID) as? Item {
            let itemView = ItemView(item, allowsOpeningBoxAndLocation: true)
                .environment(\.managedObjectContext, storage.context)
                .environment(\.storage, storage)
            let itemHostingController = UIHostingController(rootView: itemView)
            itemHostingController.title = item.name
            navigationController?.pushViewController(itemHostingController, animated: true)
        }
    }
    
    /// Create a cell registration
    private func cellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
        .init { [weak storage] cell, indexPath, item in

            var configuration = ItemContentConfiguration()

            // Name of the item
            configuration.name = item.name

            // Location of the item
            if let box = item.box, let location = box.location {
                configuration.location = .locationBox(location.name ?? "?", box.name ?? "?")
            } else {
                configuration.location = .generalSpace
            }

            // First image of the item
            if let imageIdentifier = item.imageIdentifiers.first, let imageURL = storage?.imageStore.imageURL(for: imageIdentifier) {
                configuration.imageURL = imageURL
            }

            cell.contentConfiguration = configuration
            cell.accessories = [.disclosureIndicator()]

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

    // MARK: - Fetching results
    
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

    // MARK: - Search

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
