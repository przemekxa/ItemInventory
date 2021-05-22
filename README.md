<style>
table {
    text-align: center;
}
table img {
    width: 300px;
    display: block;
    margin: 12px 0;
}
</style>
<img style="width: 128px;" src="media/icon.png" />

# Item Inventory
Item Inventory is an app that allows you to organize and manage items into boxes stored in different locations around the house.

Most of the app is written is SwiftUI, using UIKit elements when necessary.

# Screenshots
<table>
    <tr>
        <td>
            <img src="media/screenshot1.png">
            List of locations
        </td>
        <td>
            <img src="media/screenshot2.png">
            General space
        </td>
        <td>
            <img src="media/screenshot3.png">
            A location
        </td>
    </tr>
    <tr>
        <td>
            <img src="media/screenshot4.png">
            Editing a location
        </td>
        <td>
            <img src="media/screenshot5.png">
            A box
        </td>
        <td>
            <img src="media/screenshot6.png">
            Editing a box
        </td>
    </tr>
    <tr>
        <td>
            <img src="media/screenshot7.png">
            Box search
        </td>
        <td>
            <img src="media/screenshot8.png">
            An item
        </td>
        <td>
            <img src="media/screenshot9.png">
            Editing an item
        </td>
    </tr>
    <tr>
        <td>
            <img src="media/screenshot10.png">
            List of all items
        </td>
        <td>
            <img src="media/screenshot11.png">
            Item search
        </td>
        <td>
            <img src="media/screenshot12.png">
            A scanner
        </td>
    </tr>
    <tr>
        <td>
            <img src="media/screenshot13.png">
            App settings
        </td>
        <td>
            <img src="media/screenshot14.png">
            Generating QR codes
        </td>
        <td>
            <img src="media/screenshot15.png">
            Generated codes
        </td>
    </tr>
</table>

## Dependencies
- [Kingfisher](https://github.com/onevcat/Kingfisher.git) - caching and displaying images
- [swift-collections](https://github.com/apple/swift-collections) - `OrderedSet` collection
- [swift-qrcode-generator](https://github.com/fwcd/swift-qrcode-generator.git) - generating QR codes
- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation.git) - zipping and unzipping archives
