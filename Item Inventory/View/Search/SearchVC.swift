//
//  SearchVC.swift
//  Item Inventory
//
//  Created by Air on 07/05/2021.
//

import UIKit
import CoreData
import SwiftUI
import OSLog

class SearchVC: UIViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UICollectionViewDelegate {
    
    private var collectionView: UICollectionView!
    
    unowned private var storage: Storage!
    private let logger = Logger.searchVC
    
    private var resultsController: NSFetchedResultsController<Item>!

    private var searchController: UISearchController!
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>!

    // State

    private var sortAscending = (UserDefaults.standard.value(forKey: "SearchVC.sortAscending") as? Bool) ?? true {
        didSet {
            UserDefaults.standard.set(sortAscending, forKey: "SearchVC.sortAscending")
        }
    }

    private var searchByKeywords: Bool = (UserDefaults.standard.value(forKey: "SearchVC.searchByKeywords") as? Bool) ?? false {
        didSet {
            UserDefaults.standard.set(sortAscending, forKey: "SearchVC.searchByKeywords")
        }
    }
    
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
        makeMenu()

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

    /// Update the fetch request and perform the fetch
    private func updateFetch(forceFetch: Bool) {
        resultsController.fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.name, ascending: sortAscending)]

        if var searchText = searchController.searchBar.text, !searchText.isEmpty {

            // Drop last letter if there are at least 3 characters typed
            if searchText.count >= 3 {
                searchText = String(searchText.dropLast())
            }
            let newPredicate: NSPredicate
            if searchByKeywords {
                newPredicate = NSPredicate(format: "(name CONTAINS[cd] %@) OR (keywords CONTAINS[cd] %@)", searchText, searchText)
            } else {
                newPredicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
            }
            if resultsController.fetchRequest.predicate != newPredicate {
                resultsController.fetchRequest.predicate = newPredicate
                try? resultsController.performFetch()
                return
            }
        } else {
            if resultsController.fetchRequest.predicate != nil {
                resultsController.fetchRequest.predicate = nil
                try? resultsController.performFetch()
                return
            }
        }

        if forceFetch {
            try? resultsController.performFetch()
        }
    }

    // MARK: - Fetching results
    
    private func makeFetchResultsController() {
        // Create fetch request
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.name, ascending: sortAscending)]
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
        updateFetch(forceFetch: false)
        logger.debug("Searched term: \(searchController.searchBar.text ?? "EMPTY")")
    }

    // MARK: - Menu

    /// Make the right button menu
    private func makeMenu() {
        let sortAscendingAction = UIAction(title: "Ascending",
                                           image: UIImage(systemName: "arrow.up"),
                                           state: sortAscending ? .on : .off) { [weak self] action in
            self?.sortAscending = true
            self?.updateFetch(forceFetch: true)
            self?.makeMenu()
        }
        let sortDescendingAction = UIAction(title: "Descending",
                                            image: UIImage(systemName: "arrow.down"),
                                            state: sortAscending ? .off : .on) { [weak self] action in
            self?.sortAscending = false
            self?.updateFetch(forceFetch: true)
            self?.makeMenu()
        }
        let sortMenu = UIMenu(title: "", options: .displayInline, children: [sortAscendingAction, sortDescendingAction])

        let searchByKeywordsAction = UIAction(title: "Search in keywords",
                                              state: searchByKeywords ? .on : .off) { [weak self] action in
            self?.searchByKeywords.toggle()
            self?.updateFetch(forceFetch: true)
            self?.makeMenu()
        }

        let menu = UIMenu(title: "Sort by name", children: [sortMenu, searchByKeywordsAction])

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Options",
                                                            image: UIImage(systemName: "ellipsis.circle"),
                                                            primaryAction: nil,
                                                            menu: menu)
    }

}
