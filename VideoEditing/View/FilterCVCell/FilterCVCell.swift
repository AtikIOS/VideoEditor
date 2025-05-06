//
//  FilterCVCell.swift
//  VideoEditing
//
//  Created by Atik Hasan on 4/5/25.
//

import UIKit

class FilterCVCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var bgView: UIView!
    

    static let reuseIdentifier = "FilterCVCell"
    static func nib() -> UINib{
        return UINib(nibName: "FilterCVCell", bundle: nil)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
