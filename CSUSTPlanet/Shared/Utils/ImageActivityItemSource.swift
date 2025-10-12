//
//  ImageActivityItemSource.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/12.
//

import LinkPresentation
import UIKit

class ImageActivityItemSource: NSObject, UIActivityItemSource {
    private var title: String
    private var image: UIImage

    init(title: String, image: UIImage) {
        self.title = title
        self.image = image
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = self.title
        metadata.iconProvider = NSItemProvider(object: image)
        return metadata
    }
}
