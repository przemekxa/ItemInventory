//
//  ItemListCell.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 13/05/2021.
//

import UIKit
import Kingfisher

struct ItemContentConfiguration: UIContentConfiguration, Hashable {

    enum Location: Hashable {
        case generalSpace
        case locationBox(String, String)
    }

    var imageURL: URL?
    var name: String?
    var location: Location?

    func makeContentView() -> UIView & UIContentView {
        ItemContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> ItemContentConfiguration { self }
}

class ItemContentView: UIView, UIContentView {

    var currentConfiguration: ItemContentConfiguration!
    var configuration: UIContentConfiguration {
        get {
            currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? ItemContentConfiguration else { return }
            apply(configuration: newConfiguration)
        }
    }

    let imageView = UIImageView()
    let labelsStack = UIStackView()
    let nameLabel = UILabel()
    let locationLabel = UILabel()

    init(configuration: ItemContentConfiguration) {
        super.init(frame: .zero)
        setupViews()
        apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 8.0
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill

        addSubview(labelsStack)
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.axis = .vertical
        labelsStack.spacing = 4.0
        labelsStack.addArrangedSubview(nameLabel)
        labelsStack.addArrangedSubview(locationLabel)

        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.font = .preferredFont(forTextStyle: .caption1)
        locationLabel.textColor = .secondaryLabel
        locationLabel.numberOfLines = 2

        let imageBottom = imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        imageBottom.priority = .defaultHigh

        NSLayoutConstraint.activate([

            imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 10.0),
            imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            imageBottom,
            imageView.heightAnchor.constraint(equalToConstant: 64.0),
            imageView.widthAnchor.constraint(equalToConstant: 64.0),

            labelsStack.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12.0),
            labelsStack.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            labelsStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: 0.0)

        ])
    }

    private func apply(configuration: ItemContentConfiguration) {
        guard currentConfiguration != configuration else { return }
        currentConfiguration = configuration

        // Set image
        imageView.kf.setImage(with: configuration.imageURL,
                              placeholder: UIImage(named: "slash"),
                              options: [.processor(DownsamplingImageProcessor.scaled64)])
        // Set name
        nameLabel.text = configuration.name
        // Set location
        switch configuration.location {
        case .generalSpace:
            let imageAttachment = NSTextAttachment(image: UIImage(systemName: "house")!)
            let locationText = NSMutableAttributedString(attachment: imageAttachment)
            locationText.append(NSAttributedString(string: " General space"))
            locationLabel.attributedText = locationText
        case .locationBox(let location, let box):
            let locationText = NSMutableAttributedString(attachment:
                                                            NSTextAttachment(image: UIImage(systemName: "map")!))
            locationText.append(NSAttributedString(string: " " + location + "\n"))
            locationText.append(NSAttributedString(attachment:
                                                    NSTextAttachment(image: UIImage(systemName: "archivebox")!)))
            locationText.append(NSAttributedString(string: " " + box))
            locationLabel.attributedText = locationText
        case .none:
            locationLabel.attributedText = nil
        }
    }

}
