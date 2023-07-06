//
//  MeasureController.swift
//  Created by Ben on July 06, 2023.
//

import Foundation
import UIKit
import CoreData
import CocoaLumberjackSwift

class MeasureController: BaseMeasureMapController, UITableViewDataSource, UITableViewDelegate {

    private var fetchedResultsController: NSFetchedResultsController<Measure>!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tvNoItemsFound: UILabel!

    var alertCantLoadPreviewIsDisplayed = false
    var alreadyDisplayedAlertPreview = false

    override func viewDidLoad() {
        super.viewDidLoad()
        DDLogVerbose("viewDidLoad()")
        setupFetchedResultsController()
        handleEmptyView()
    }

    @IBAction func newMeasure(_ sender: Any) {
        performMeasureSegue(withIdentifier: MeasureEditorController.FROM_MEASURES_SEGUE_ID, sender: nil)
    }

    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Measure> = Measure.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "measures")
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    func deleteMeasure(at indexPath: IndexPath) {
        let measureToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(measureToDelete)
        try? dataController.viewContext.save()
    }

    func handleEmptyView() {
        tvNoItemsFound.isHidden = fetchedResultsController.fetchedObjects?.count != 0
    }

    // MARK: Table Functions
    func numberOfSections(in tableView: UITableView) -> Int {
        fetchedResultsController.sections?.count ?? 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let measure = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: MeasureViewCell.IDENTIFIER, for: indexPath) as! MeasureViewCell

        cell.tvTitle.text = measure.name
        cell.tvDescription.text = measure.getDescription()
        
        if cell.ivMap?.image == nil {
            cell.startLoading()
            RestAPiClient.downloadMapData(measure.simplePoints ?? "", needsFill: measure.needsFill(), color: measure.group!.color.toRgbHexString()) { [self] data, error in
                cell.stopLoading()

                if error != nil {
                    // To prevent call too many alerts and display again if a preview was loaded successfully
                    if !alertCantLoadPreviewIsDisplayed && !alreadyDisplayedAlertPreview {
                        let alertVC = UIAlertController(title: "Can't load map preview", message: "", preferredStyle: .alert)
                    
                        alertVC.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                            self.alertCantLoadPreviewIsDisplayed = false
                        }))
                        alertCantLoadPreviewIsDisplayed = true
                        alreadyDisplayedAlertPreview = true
                        present(alertVC, animated: true)
                    }
                } else {
                    alreadyDisplayedAlertPreview = false
                }
                
                guard let data = data else {
                    let image = UIImage(named: "no_image")
                    cell.ivMap?.image = image
                    cell.setNeedsLayout()

                    return
                }

                let image = UIImage(data: data)
                cell.ivMap?.image = image
                cell.setNeedsLayout()
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete: deleteMeasure(at: indexPath)
        default: ()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let measure = fetchedResultsController.object(at: indexPath)
        performMeasureSegue(withIdentifier: MeasureEditorController.FROM_MEASURES_SEGUE_ID, sender: measure)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

extension MeasureController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            break
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            break
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        @unknown default:
            fatalError()
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: tableView.insertSections(indexSet, with: .fade)
        case .delete: tableView.deleteSections(indexSet, with: .fade)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        @unknown default:
            fatalError()
        }
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        tableView.reloadData()
        handleEmptyView()
    }
}
