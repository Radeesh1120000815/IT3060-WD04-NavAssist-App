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