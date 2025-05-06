//
//  SpeedCell.swift
//  VideoEditing
//
//  Created by Atik Hasan on 4/17/25.
//

import UIKit

class SpeedCell: UICollectionViewCell {

    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    static let reuseIdentifier = "SpeedCell"
    static func nib() -> UINib{
        return UINib(nibName: "SpeedCell", bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
       self.bgView.backgroundColor = .white
        self.bgView.layer.cornerRadius = 15
    }

}
