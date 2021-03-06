//
//  AlbumTrackCell.swift
//  JamAlpha2
//
//  Created by Song Liao on 8/23/15.
//  Copyright (c) 2015 Song Liao. All rights reserved.
//

import UIKit

class AlbumTrackCell: UITableViewCell {

    @IBOutlet weak var trackNumberLabel: UILabel!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var loudspeakerImage: UIImageView!
    @IBOutlet weak var titleTrailingConstant: NSLayoutConstraint!
    //50 if loudspeaker is shown, 15 otherwise
    @IBOutlet weak var cloudImage: UIImageView!
    
    @IBOutlet weak var titleLeadingConstraint: NSLayoutConstraint!
    
    
    
}
