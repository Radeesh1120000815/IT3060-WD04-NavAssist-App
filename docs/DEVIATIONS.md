# Deviations from Milestone 02 Wireframes

This log records every point where the implemented app differs from the wireframes and variant selections documented in Milestone 02, with the reason for each change. 

Referenced in the final report's "Implementation details" and "Deviations" sections.

| # | Screen  | Deviation | Reason |
|---|-------- |-----------|--------|
| 1 |  Home    | Added a blue accent colour (#1B4FD8) and light tints/shadows instead of plain black-and-white | Milestone 02 wireframes were intentionally low-fidelity (black/white) for sketching; a light colour theme was added during implementation for visual polish. Layout, elements and order are unchanged from the selected Variant A. |

| 2 |  Home    | Added a small compass icon next to the "NavAssist" title | Minor branding touch not specified in the wireframe; does not affect any functional element or UR-09 compliance. |

| 3 | Search Destination | Added a "Search '[query]'" confirmation button that appears after voice input finishes, before submitting | The wireframe assumed voice input submits immediately; a confirmation step was added so the user can correct a misheard voice result before it is saved to Firestore and searched — improves UR-01 accuracy without changing the two-input-method design. |

| 4 | Search Destination | Recent searches list reads live from Firestore instead of static placeholder data | Required to satisfy the CRUD/working-app requirement for Milestone 03; Milestone 02 only showed static example data since it was a prototype, not a working app. |

| 5 |  Home / Search     | Recent searches use a live Firestore stream with duplicate-prevention (same search updates timestamp instead of creating a new entry) | Needed for a working app — static wireframe didn't address real data behaviour; prevents the recent list from filling with repeated identical entries. |

| 6 | Destination Selection | Results are generated as realistic mock variations of the search term, not from a live maps/places API | No real-time places/maps API (e.g., Google Places) was integrated within the project timeframe; results demonstrate the intended UI/UX and selection flow with representative data instead. |

| 7 |   Route Options    | Route data (time, distance, safety note) generated as representative fixed values rather than from a live routing/directions API | No live routing API (e.g., Google Directions) integrated within the project timeframe; the three-option, safety-first comparison pattern from the selected Variant B wireframe is preserved with realistic placeholder data. |

| 8 |   Route Details    | Turn-by-turn steps and safety warnings shown as representative fixed content rather than from a live routing/directions API | Consistent with the Route Options limitation — no live directions API integrated in this timeframe; the step-by-step, warnings-included layout from the selected Variant A wireframe is preserved. |

| 9 |   Start Navigation | Map preview is a placeholder icon/label instead of a real interactive map | No live maps SDK (eg., Google Maps) integrated in this timeframe; audio (text-to-speech) and vibration feedback are fully functional and real, satisfying UR-01 and UR-03, while the visual map remains a placeholder pending future map integration. |

### CRUD compliance additions (Milestone 03 requirement: minimum 2 CRUD operations per interface)

| 10 |    Home   | Added swipe-to-delete on recent search items (not shown in the Milestone 02 wireframe) | Required to demonstrate a working Delete operation per the Milestone 03 CRUD requirement (minimum 2 CRUD operations per interface); the wireframe only specified a static recent-searches list. |

| 11 | Destination Selection | Added a "Save to Favorites" heart icon on each result card (not shown in the Milestone 02 wireframe) | Required to demonstrate a working Create operation per the Milestone 03 CRUD requirement; builds on the existing "selectable result" interaction without changing the core list/selection layout from Variant A. |

| 12 |  Route Options | Added silent saving of the user's selected route as a preference (no new visible UI element) | Required to demonstrate Create/Update operations per the Milestone 03 CRUD requirement; implemented as a background action triggered by the existing "Select Route" button rather than adding a new interface element, to preserve the approved Variant B layout. |

| 13 |  Route Details | Added a background "route viewed" history record, created on screen load and marked reviewed when Start Navigation is tapped (no new visible UI element) | Required to demonstrate Create/Update operations per the Milestone 03 CRUD requirement; implemented invisibly to preserve the step-by-step layout from the approved Variant A wireframe. |

| 14 |  Start Navigation | Added a background navigation session record, created when navigation starts and updated to "ended" when the user taps End Navigation (no new visible UI element) | Required to demonstrate Create/Update operations per the Milestone 03 CRUD requirement; implemented invisibly to preserve the map + instruction + audio/vibration layout from the approved Variant B wireframe. |

| 15 |   Route Options  | Route preference storage changed from a single global record to one record per destination (matched by destination name) | Initial implementation only stored one overall preferred route regardless of destination, which didn't reflect realistic usage where a user may prefer different routes for different places; corrected to key preferences by destination name. |

| 16 | Home, (new) Places | Removed Profile tab (no sign-in/account system exists); repurposed Places tab to show saved Favorites instead of duplicating the Home screen's recent searches | App uses anonymous authentication only, so a Profile tab with no account data would be a dead-end, unhelpful for voice/touch navigation; Favorites previously had no screen to view them after saving, so Places was given a clear, distinct purpose instead of overlapping with Home. |

| 17 | Route Details | The road-crossing/construction warning block is now tappable and opens the Community Hazards screen | Connects the route safety warning to community-reported hazards (UR-06); the block's appearance is unchanged apart from a "Tap to view community reports" line and a chevron. |