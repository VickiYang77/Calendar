//
//  ViewController.swift
//  Calendar
//
//  Created by Vicki Yang on 2023/7/7.
//

import UIKit
import EventKit
import EventKitUI

class ViewController: UIViewController {
    let eventManager = CalendarManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func ShowEditViewBtn(_ sender: Any) {
        eventManager.sendCalendarEvent(self, title: "edit Event", startTime: "202308240700", endTime: "202308241400", notes: "備註欄", alarmTime: 8)
    }
    
    @IBAction func AddEventBtn(_ sender: Any) {
        eventManager.sendCalendarEvent(self, title: "add Event", startTime: "202308220700", endTime: "202308221400", notes: "備註欄", alarmTime: 8, isShowEditView: false) { result in
            switch result {
            case .success():
                let alert = UIAlertController(title: "提醒", message: "行事曆事件已添加！", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
                self.present(alert, animated: true)
            case .failure(let error):
                print("Error：\(error.localizedDescription)")
            }
        }
    }
    
}

extension ViewController: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true)
    }
}

// MARK: - CalendarManager

struct CalendarEvent {
    let title: String
    let startTime: String
    let endTime: String
    let notes: String
    let alarmTime: Double
    
    var startDate: Date {
        return startTime.yyyyMMddHHmmToDate()
    }
    
    var endDate: Date {
        return endTime.yyyyMMddHHmmToDate()
    }
}

class CalendarManager {
    func sendCalendarEvent(_ sourceVC: UIViewController, title: String = "", startTime: String = "", endTime: String = "", notes: String = "", alarmTime: Double = 0, isShowEditView: Bool = true, completion: ((Result<Void, Error>) -> Void)? = nil) {
        let calendarEvent = CalendarEvent(title: title, startTime: startTime, endTime: endTime, notes: notes, alarmTime: alarmTime)
        
        let eventStore = EKEventStore()
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            // 已授權
            DispatchQueue.main.async {
                isShowEditView ? self.showEditView(eventStore, calendarEvent: calendarEvent, sourceVC: sourceVC) : self.insertEvent(eventStore, calendarEvent: calendarEvent, completion: completion)
            }
        case .denied:
            // 拒絕授權
            let alert = UIAlertController(title: "提醒", message: "請去系統設定開啟行事曆權限！", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
            sourceVC.present(alert, animated: true)
        case .notDetermined:
            // 初次請求權限許可
            eventStore.requestAccess(to: .event, completion: { [weak self] (granted, error) in
                guard let self = self else { return }
                if granted {
                    DispatchQueue.main.async {
                        isShowEditView ? self.showEditView(eventStore, calendarEvent: calendarEvent, sourceVC: sourceVC) : self.insertEvent(eventStore, calendarEvent: calendarEvent, completion: completion)
                    }
                } else {
                    print("Calendar Access denied")
                }
            })
        default:
            print("Calendar Case default")
        }
    }
    
    // 顯示行事曆編輯頁
    private func showEditView(_ eventStore: EKEventStore, calendarEvent: CalendarEvent, sourceVC: UIViewController) {
        let event = createEKEvent(eventStore, calendarEvent: calendarEvent)
        let eventController = EKEventEditViewController()
        eventController.eventStore = eventStore
        eventController.event = event
        eventController.editViewDelegate = sourceVC as? any EKEventEditViewDelegate
        sourceVC.present(eventController, animated: true, completion: nil)
    }
    
    // 背景新增行事曆Event
    private func insertEvent(_ eventStore: EKEventStore, calendarEvent: CalendarEvent, completion: ((Result<Void, Error>) -> Void)? = nil) {
        do {
            let event = createEKEvent(eventStore, calendarEvent: calendarEvent)
            try eventStore.save(event, span: .thisEvent)
            completion?(.success(()))
        } catch let error as NSError {
            completion?(.failure(error))
        }
    }
    
    // 創建event物件 (注意：一定要等用戶允許授權後才可以創建)
    private func createEKEvent(_ eventStore: EKEventStore, calendarEvent: CalendarEvent) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.startDate = calendarEvent.startDate
        event.endDate = calendarEvent.endDate
        event.title = calendarEvent.title
        event.notes = calendarEvent.notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        let alarm = EKAlarm(relativeOffset: -60 * calendarEvent.alarmTime)
        event.addAlarm(alarm)   // 事件前幾分鐘提醒
        
        return event
    }
}

extension String {
    func yyyyMMddHHmmToDate() -> Date {
        return self.toDate(format: "yyyyMMddHHmm")
    }
    
    func toDate(format: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        if let date = dateFormatter.date(from: self) {
            return date
        } else {
            return Date()
        }
    }
}

