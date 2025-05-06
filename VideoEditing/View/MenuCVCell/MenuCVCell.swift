//
//  MenuCVCell.swift
//  VideoEditing
//
//  Created by Atik Hasan on 4/5/25.
//

import UIKit

class MenuCVCell: UICollectionViewCell {

    @IBOutlet weak var iamgeView: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    
    
    static let reuseIdentifier = "MenuCVCell"
    static func nib() -> UINib{
        return UINib(nibName: "MenuCVCell", bundle: nil)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

}
