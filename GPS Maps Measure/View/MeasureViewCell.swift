//
//  MeasureViewCell.swift
//  Created by Ben on July 06, 2023.
//

import Foundation
import UIKit

class MeasureViewCell: UITableViewCell {
    static let IDENTIFIER = "MeasureCell"
    //ivmAP
    @IBOutlet weak var ivMap: UIImageView!
    //tvTitle
    @IBOutlet weak var tvTitle: UILabel!
    //tvDescription
    @IBOutlet weak var tvDescription: UILabel!
    //loadingIndicator
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    func startLoading() {
        //start animation
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        ivMap.isHidden = true
    }

    func stopLoading() {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        ivMap.isHidden = false
    }
}
