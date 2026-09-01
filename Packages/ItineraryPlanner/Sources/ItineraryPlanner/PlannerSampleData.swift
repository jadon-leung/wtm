import Foundation

/// Hardcoded stand-in for real venue data (the Places API replaces this) and
/// for the initial state of a fresh day plan. Deliberately keeps a couple of
/// venues duplicated between `initialSlots`'s alternatives and `catalog` —
/// e.g. "Casa Verde" and "Micheltorena Stairs" appear in both, with
/// different ids — matching the original prototype's lack of a single
/// deduped venue store. Adding a venue that's already in the day isn't
/// prevented here either; a real venue store should dedupe by id.
enum PlannerSampleData {
    static func initialSlots() -> [PlannerSlot] {
        [
            PlannerSlot(
                id: UUID(),
                venue: PlannerVenue(
                    id: UUID(), name: "Sunroom Coffee", category: "Coffee", durationMin: 45,
                    rating: 4.7, lat: 34.0900, lng: -118.2700,
                    why: "Bright, plant-filled patio that's never too loud for a slow morning coffee.",
                    note: nil
                ),
                alternatives: [
                    PlannerVenue(
                        id: UUID(), name: "Marfa Roasters", category: "Coffee", durationMin: 45,
                        rating: 4.5, lat: 34.0921, lng: -118.2735,
                        why: "Small-batch beans and a quieter counter if Sunroom's patio is packed.",
                        note: "Quieter"
                    ),
                    PlannerVenue(
                        id: UUID(), name: "Casa Verde", category: "Coffee", durationMin: 40,
                        rating: 4.4, lat: 34.0875, lng: -118.2680,
                        why: "Courtyard seating with good people-watching on the boulevard.",
                        note: nil
                    )
                ]
            ),
            PlannerSlot(
                id: UUID(),
                venue: PlannerVenue(
                    id: UUID(), name: "Reseda Vintage", category: "Shopping", durationMin: 50,
                    rating: 4.3, lat: 34.0958, lng: -118.2740,
                    why: "Curated racks, not a rummage — worth the extra few dollars per piece.",
                    note: nil
                ),
                alternatives: [
                    PlannerVenue(
                        id: UUID(), name: "Yellow Bird Vintage", category: "Shopping", durationMin: 45,
                        rating: 4.2, lat: 34.0940, lng: -118.2711,
                        why: "Deeper discount bin if you're hunting rather than browsing.",
                        note: nil
                    ),
                    PlannerVenue(
                        id: UUID(), name: "Micheltorena Stairs", category: "Scenery", durationMin: 30,
                        rating: 4.6, lat: 34.0890, lng: -118.2790,
                        why: "A steep painted staircase with a skyline view if you'd rather walk than shop.",
                        note: "Free"
                    )
                ]
            )
        ]
    }

    static func catalog() -> [CatalogGroup] {
        [
            CatalogGroup(key: "food", label: "Food", blurb: "Sit-down meals worth the wait.", options: [
                PlannerVenue(
                    id: UUID(), name: "Rambutan Thai", category: "Thai", durationMin: 75,
                    rating: 4.8, lat: 34.0872, lng: -118.2705,
                    why: "The kind of curry that makes you slow down and stop talking for a minute.",
                    note: nil
                ),
                PlannerVenue(
                    id: UUID(), name: "Sabana", category: "Thai", durationMin: 60,
                    rating: 4.4, lat: 34.0902, lng: -118.2668,
                    why: "Faster tables if the group's already running late.",
                    note: nil
                ),
                PlannerVenue(
                    id: UUID(), name: "All Time", category: "American", durationMin: 65,
                    rating: 4.6, lat: 34.0933, lng: -118.2752,
                    why: "A backyard-feeling patio that's good for bigger groups.",
                    note: nil
                )
            ]),
            CatalogGroup(key: "dessert", label: "Dessert", blurb: "Something sweet to close a stop out.", options: [
                PlannerVenue(
                    id: UUID(), name: "Kumquat Coffee & Ice Cream", category: "Dessert", durationMin: 30,
                    rating: 4.6, lat: 34.0887, lng: -118.2699,
                    why: "Small-batch flavors that rotate weekly.",
                    note: nil
                ),
                PlannerVenue(
                    id: UUID(), name: "Konbi", category: "Dessert", durationMin: 25,
                    rating: 4.7, lat: 34.0801, lng: -118.2551,
                    why: "Worth the short drive for the milk bread alone.",
                    note: "Popular"
                ),
                PlannerVenue(
                    id: UUID(), name: "Loving Hut", category: "Dessert", durationMin: 30,
                    rating: 4.2, lat: 34.0949, lng: -118.2703,
                    why: "Vegan option that doesn't taste like a compromise.",
                    note: nil
                )
            ]),
            CatalogGroup(key: "drinks", label: "Drinks", blurb: "Bars and coffee to punctuate the day.", options: [
                PlannerVenue(
                    id: UUID(), name: "Bar Stella", category: "Drinks", durationMin: 60,
                    rating: 4.5, lat: 34.0918, lng: -118.2688,
                    why: "A patio bar nearby if the plan shifts from dinner to drinks.",
                    note: nil
                ),
                PlannerVenue(
                    id: UUID(), name: "Marfa Roasters", category: "Coffee", durationMin: 45,
                    rating: 4.5, lat: 34.0921, lng: -118.2735,
                    why: "Small-batch beans and a quieter counter if Sunroom's patio is packed.",
                    note: "Quieter"
                ),
                PlannerVenue(
                    id: UUID(), name: "El Prado", category: "Drinks", durationMin: 60,
                    rating: 4.4, lat: 34.0865, lng: -118.2789,
                    why: "Dim, unfussy, and rarely a wait before 9pm.",
                    note: nil
                )
            ]),
            CatalogGroup(key: "activity", label: "Activity", blurb: "Something to do, not just somewhere to sit.", options: [
                PlannerVenue(
                    id: UUID(), name: "Micheltorena Stairs", category: "Scenery", durationMin: 30,
                    rating: 4.6, lat: 34.0890, lng: -118.2790,
                    why: "A steep painted staircase with a skyline view if you'd rather walk than shop.",
                    note: "Free"
                ),
                PlannerVenue(
                    id: UUID(), name: "Spoke Bicycle Cafe", category: "Activity", durationMin: 60,
                    rating: 4.3, lat: 34.0838, lng: -118.2661,
                    why: "Rent bikes and loop the reservoir if the group wants to move.",
                    note: nil
                ),
                PlannerVenue(
                    id: UUID(), name: "Silver Lake Meadow", category: "Scenery", durationMin: 40,
                    rating: 4.5, lat: 34.0865, lng: -118.2703,
                    why: "Open lawn right on the reservoir loop, good for a lazy hour.",
                    note: "Free"
                )
            ]),
            CatalogGroup(key: "scenery", label: "Scenery", blurb: "Views and walks, no purchase required.", options: [
                PlannerVenue(
                    id: UUID(), name: "Silver Lake Reservoir Loop", category: "Scenery", durationMin: 45,
                    rating: 4.7, lat: 34.0908, lng: -118.2707,
                    why: "The full loop is under 2.5 miles and mostly flat.",
                    note: "Free"
                ),
                PlannerVenue(
                    id: UUID(), name: "Micheltorena Stairs", category: "Scenery", durationMin: 30,
                    rating: 4.6, lat: 34.0890, lng: -118.2790,
                    why: "A steep painted staircase with a skyline view if you'd rather walk than shop.",
                    note: "Free"
                ),
                PlannerVenue(
                    id: UUID(), name: "Bellevue Park", category: "Scenery", durationMin: 35,
                    rating: 4.3, lat: 34.0779, lng: -118.2622,
                    why: "Quiet hillside park most visitors miss.",
                    note: nil
                )
            ]),
            CatalogGroup(key: "shopping", label: "Shopping", blurb: "Browsing, not errands.", options: [
                PlannerVenue(
                    id: UUID(), name: "Reseda Vintage", category: "Shopping", durationMin: 50,
                    rating: 4.3, lat: 34.0958, lng: -118.2740,
                    why: "Curated racks, not a rummage — worth the extra few dollars per piece.",
                    note: nil
                ),
                PlannerVenue(
                    id: UUID(), name: "Yellow Bird Vintage", category: "Shopping", durationMin: 45,
                    rating: 4.2, lat: 34.0940, lng: -118.2711,
                    why: "Deeper discount bin if you're hunting rather than browsing.",
                    note: nil
                ),
                PlannerVenue(
                    id: UUID(), name: "Casa Verde", category: "Coffee", durationMin: 40,
                    rating: 4.4, lat: 34.0875, lng: -118.2680,
                    why: "Courtyard seating with good people-watching on the boulevard.",
                    note: nil
                )
            ])
        ]
    }
}
