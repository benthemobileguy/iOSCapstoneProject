//
//  GroupEditorController.swift
//  Created by Ben on July 06, 2023.
//

import UIKit
import CocoaLumberjackSwift

class GroupEditorController: UIViewController, UIColorPickerViewControllerDelegate {
    private static let CONTROLLER_ID = "GroupEditorController"

    private let dataController = (UIApplication.shared.delegate as! AppDelegate).dataController

    private var group: Group? = nil

    @IBOutlet weak var ivSelectColor: UIImageView!
    @IBOutlet weak var tfGroupName: UITextField!

    // Launch the GroupEditorController for creating a new group
    static func launchForNew(_ viewController: UIViewController) {
        let newController = viewController.storyboard?.instantiateViewController(withIdentifier: CONTROLLER_ID) as! GroupEditorController
        newController.group = nil
        viewController.present(newController, animated: true, completion: nil)
    }

    // Launch the GroupEditorController for editing an existing group
    static func launchForEdit(_ viewController: UIViewController, _ group: Group) {
        let newController = viewController.storyboard?.instantiateViewController(withIdentifier: CONTROLLER_ID) as! GroupEditorController
        newController.group = group
        viewController.present(newController, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        DDLogVerbose("viewDidLoad")

        // Add tap gesture recognizer to the image view for color selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onImageToSelectTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        ivSelectColor.isUserInteractionEnabled = true
        ivSelectColor.addGestureRecognizer(tapGesture)

        tfGroupName.delegate = self

        if isNewGroup() {
            populateDefault() // Populate default values for a new group
        } else {
            populateGroup() // Populate values for an existing group
        }
    }

    // Handle tap gesture on the image view for color selection
    @objc func onImageToSelectTap(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            DDLogVerbose("onImageToSelectTap()")
            selectColor() // Show color picker when the image view is tapped
        }
    }

    // Save the group when the "Save" button is pressed
    @IBAction func saveGroup(_ sender: Any) {
        let name = tfGroupName.text

        if name == nil || name?.isEmpty == true {
            showSingleViewAlertAction("Name is required") // Show an alert if the name is empty
            return
        }

        if isNewGroup() {
            group = Group(context: dataController.viewContext) // Create a new group if it doesn't exist
        }

        group?.name = name
        group?.updatedAt = Date()

        if let color = ivSelectColor.backgroundColor?.rgb() {
            group?.color = Int64(color)
        } else {
            group?.color = 0
        }

        try? dataController.viewContext.save() // Save changes to the data context
        dismiss(animated: true)
    }

    // Cancel editing and dismiss the GroupEditorController
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }

    // Populate default values for a new group
    private func populateDefault() {
        ivSelectColor.backgroundColor = UIColor.blue
        tfGroupName.text = ""
    }

    // Populate values for an existing group
    private func populateGroup() {
        ivSelectColor.backgroundColor = group!.color.uiColor()
        tfGroupName.text = group?.name
    }

    // Check if the group is new or existing
    private func isNewGroup() -> Bool {
        group == nil
    }

    // Show the color picker for selecting a color
    private func selectColor() {
        let pickerController = UIColorPickerViewController()
        if let color = ivSelectColor.backgroundColor {
            pickerController.selectedColor = color
        }
        pickerController.delegate = self
        present(pickerController, animated: true, completion: nil)
    }

    // Handle the color picker selection
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        ivSelectColor.backgroundColor = viewController.selectedColor
    }
}

// Implement UITextFieldDelegate for handling text field interactions
extension GroupEditorController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true) // Dismiss the keyboard when "Return" is pressed
        return false
    }
}
