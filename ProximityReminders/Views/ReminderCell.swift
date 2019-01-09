//
//  ReminderCell.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/9/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import UIKit

/// A cell that shows info for a reminder.
class ReminderCell: UITableViewCell {
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    /// Configure this view with a reminder.
    /// - Parameter reminder: The reminder to configure with.
    func configure(with reminder: Reminder) {
        noteLabel.text = reminder.note
        addressLabel.text = reminder.locationAddress
    }
}
