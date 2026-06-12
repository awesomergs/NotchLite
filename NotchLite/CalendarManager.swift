//
//  CalendarManager.swift
//  NotchLite
//
//  Created by Rohan George on 6/12/26.
//

import EventKit
import SwiftUI
import Combine

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarColor: Color
    let meetingURL: URL?
}

class CalendarManager: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var showingTomorrow = false
    @Published var authorized = false

    private let store = EKEventStore()
    private var refreshTimer: AnyCancellable?

    init() {
        requestAccess()
    }

    private func requestAccess() {
        store.requestFullAccessToEvents { [weak self] granted, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.authorized = granted
                if granted {
                    self.fetchEvents()
                    self.startRefreshTimer()
                }
            }
        }
    }

    func fetchEvents() {
        let cal = Calendar.current
        let now = Date()
        let tomorrow = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now)!)
        let dayAfter = cal.date(byAdding: .day, value: 1, to: tomorrow)!

        let todayEvents = eventsInRange(from: now, to: tomorrow)
        if !todayEvents.isEmpty {
            events = todayEvents
            showingTomorrow = false
            return
        }

        let tomorrowEvents = eventsInRange(from: tomorrow, to: dayAfter)
        if let first = tomorrowEvents.first {
            events = [first]
            showingTomorrow = true
        } else {
            events = []
            showingTomorrow = false
        }
    }

    private func eventsInRange(from start: Date, to end: Date) -> [CalendarEvent] {
        let pred = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: pred)
            .sorted { $0.startDate < $1.startDate }
            .map { CalendarEvent(ekEvent: $0) }
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.fetchEvents() }
    }
}

private extension CalendarEvent {
    init(ekEvent: EKEvent) {
        let eid: String? = ekEvent.eventIdentifier
        id = eid ?? UUID().uuidString
        title = ekEvent.title ?? "Untitled"
        startDate = ekEvent.startDate
        endDate = ekEvent.endDate ?? ekEvent.startDate
        isAllDay = ekEvent.isAllDay
        calendarColor = Color(cgColor: ekEvent.calendar.cgColor)
        meetingURL = CalendarEvent.extractMeetingURL(from: ekEvent)
    }

    static func extractMeetingURL(from event: EKEvent) -> URL? {
        if let url = event.url, isMeetingURL(url) { return url }
        guard let notes = event.notes else { return nil }
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(notes.startIndex..., in: notes)
        let matches = detector?.matches(in: notes, range: range) ?? []
        return matches.compactMap(\.url).first(where: isMeetingURL)
    }

    private static func isMeetingURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("zoom.us") ||
               host.contains("meet.google.com") ||
               host.contains("teams.microsoft.com") ||
               host.contains("teams.live.com") ||
               host.contains("webex.com") ||
               host.contains("gotomeeting.com") ||
               host.contains("whereby.com") ||
               host.contains("bluejeans.com") ||
               host.contains("chime.aws")
    }
}
