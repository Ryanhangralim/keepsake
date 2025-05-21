//
//  keepsakeWidget.swift
//  keepsakeWidget
//
//  Created by Agustio Maitimu on 19/05/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
	typealias Intent = ConfigurationAppIntent
	
	func placeholder(in context: Context) -> SimpleEntry {
		SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
	}
	
	func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
		SimpleEntry(date: Date(), configuration: configuration)
	}
	
	func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
		var entries: [SimpleEntry] = []
		let currentDate = Date()
		let entry = SimpleEntry(date: currentDate, configuration: configuration)
		entries.append(entry)
		
		return Timeline(entries: entries, policy: .never)
	}
	
	//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
	//        // Generate a list containing the contexts this widget is relevant in.
	//    }
}

struct SimpleEntry: TimelineEntry {
	let date: Date
	let configuration: ConfigurationAppIntent
}


struct KipsekWidgetEntryView: View {
	@Environment(\.colorScheme) var colorScheme
	var entry: Provider.Entry
	
	var body: some View {
		VStack {
			if let album = entry.configuration.album {
				Text(album.title)
					.foregroundStyle(.red)
			} else {
				Text("Tap & Hold -> Edit Widget")
					.frame(maxWidth: .infinity, alignment: .center)
					.foregroundStyle(.red)
			}
		}
		.widgetURL(URL(string: "keepsake://select-folder?folder=\(entry.configuration.album?.id ?? "Failed")"))
		.containerBackground(for: .widget) {
			Color.white
		}
	}
}


struct KipsekWidget: Widget {
	var body: some WidgetConfiguration {
		AppIntentConfiguration(kind: "group.com.keepsake", intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
			KipsekWidgetEntryView(entry: entry)
		}
		.configurationDisplayName("Kipsek")
		.description("Auto-Sorter Camera")
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
	}
}



//#Preview(as: .systemSmall) {
//	KipsekWidget()
//} timeline: {
//	SimpleEntry(date: .now, configuration: {
//		let intent = ConfigurationAppIntent()
//		intent.folder = "Food"
//		return intent
//	}())
//}
