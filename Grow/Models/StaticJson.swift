//
//  SchemaJson.swift
//  Grow
//
//  Created by Swen Rolink on 12/06/2021.
//

import Foundation

struct JsonOverviewResponse {
    
    var jsonString: String
    
    init(){
        jsonString =
    """
{
    "trainee": "Swen",
    "days": [
        {
            "type": "Rust"
      },
        {
            "type": "Bovenlichaam",
            "exercises": [
                {
                    "set": [
                        {
                            "exercise": {
                                "name": "Bench press",
                                "reps": 6,
                                "sets": 4,
                                "pb": 91
                            }
                  },
                        {
                            "exercise": {
                                "name": "Chin ups",
                                "reps": 6,
                                "sets": 4,
                                "pb": 0
                            }
                  }
               ]
            },
                {
                    "set": [
                        {
                            "exercise": {
                                "name": "Overhead press",
                                "reps": 8,
                                "sets": 4,
                                "pb": 48
                            }
                  },
                        {
                            "exercise": {
                                "name": "T bar row",
                                "reps": 4,
                                "sets": 4,
                                "pb": 85
                            }
                  }
               ]
            },
                {
                    "set": [
                        {
                            "exercise": {
                                "name": "Cable fly",
                                "reps": 12,
                                "sets": 3,
                                "pb": 65
                            }
                  },
                        {
                            "exercise": {
                                "name": "Reverse cable fly",
                                "reps": 12,
                                "sets": 3,
                                "pb": 15
                            }
                  }
               ]
            },
                {
                    "set": [
                        {
                            "exercise": {
                                "name": "EZ-bar lying triceps extension",
                                "reps": 8,
                                "sets": 3,
                                "pb": 57
                            }
                  },
                        {
                            "exercise": {
                                "name": "EZ-bar biceps curl",
                                "reps": 10,
                                "sets": 3,
                                "pb": 42
                            }
                  }
               ]
            }
         ]
      },
        {
            "type": "Onderlichaam",
            "exercises": [
                {
                    "set": [{
                        "exercise": {
                            "name": "Squat",
                            "reps": 8,
                            "sets": 4
                        },
                        "exercise": {
                            "name": "Barbell romanian deadlift",
                            "reps": 8,
                            "sets": 4
                        }
                    }]
            },
                {
                    "set": [{
                        "exercise": {
                            "name": "Bulgarian split squat",
                            "reps": 10,
                            "sets": 4
                        },
                        "exercise": {
                            "name": "Leg curl",
                            "reps": 12,
                            "sets": 4
                        }
                    }]
            },
                {
                    "set": [{
                        "exercise": {
                            "name": "Leg extension",
                            "reps": 12,
                            "sets": 3
                        },
                        "exercise": {
                            "name": "Seated calf raises",
                            "reps": 15,
                            "sets": 3
                        }
                    }]
            },
                {
                    "set": [{
                        "exercise": {
                            "name": "Hanging leg raise",
                            "reps": 10,
                            "sets": 3
                        }
                    }]
            }
         ]
      },
        {
            "type": "Bovenlichaam",
            "exercises": [
                {
                    "set": [{
                        "exercise": {
                            "name": "Weigthed push-up",
                            "reps": 8,
                            "sets": 4
                        },
                        "exercise": {
                            "name": "Barbell bent over row",
                            "reps": 10,
                            "sets": 4
                        }
                    }]
            },
                {
                    "set": [
                        {
                            "exercise": {
                                "name": "Barbell incline bench press",
                                "reps": 10,
                                "sets": 3
                            },
                            "exercise": {
                                "name": "One arm lat pull down",
                                "reps": 12,
                                "sets": 4
                            }
                  }]
            },
                {
                    "set": [{
                        "exercise": {
                            "name": "Reverse Cable fly",
                            "reps": 15,
                            "sets": 3
                        }
                    }]
            },
                {
                    "set": [
                        {
                            "exercise": {
                                "name": "Dumbbell standing bicep curls",
                                "reps": 12,
                                "sets": 3
                            },
                            "exercise": {
                                "name": "Pulley rope standing triceps extension",
                                "reps": 15,
                                "sets": 3
                            }
                  }]
            }
         ]
      },
        {
            "type": "Rust"
      },
        {
            "type": "Onderlichaam",
            "exercises": [
                {
                    "set": [
                        {
                            "exercise": {
                                "name": "Deadlift",
                                "reps": 5,
                                "sets": 4
                            }
                    }]
            },
                {
                    "set": [{
                        "exercise": {
                            "name": "Barbell split squat",
                            "reps": 12,
                            "sets": 4
                        },
                        "exercise": {
                            "name": "Hyperextension",
                            "reps": 12,
                            "sets": 3
                        }
                }]
            },
                {
                    "set": [{
                        "exercise": {
                            "name": "Leg extension",
                            "reps": 15,
                            "sets": 3
                        },
                        "exercise": {
                            "name": "Seated calf raise",
                            "reps": 15,
                            "sets": 3
                        }
                    }]
            }
         ]
}, {
            "type": "Bovenlichaam",
            "exercises": [
                {
                    "set": [{
                        "exercise": {
                            "name": "Incline dumbbell press",
                            "reps": 12,
                            "sets": 3
                        },
                        "exercise": {
                            "name": "Dumbbell row incline",
                            "reps": 15,
                            "sets": 3
                        }
                    }]
            },
                {
                    "set": [{
                        "exercise": {
                            "name": "Dumbbell deep push up",
                            "reps": 15,
                            "sets": 3
                        },
                        "exercise": {
                            "name": "Lat prayer",
                            "reps": 15,
                            "sets": 3
                        }
                    }]
            },
                {
                    "set": [{
                        "exercise": {
                            "name": "Upper chest cable fly",
                            "reps": 15,
                            "sets": 3
                        },
                        "exercise": {
                            "name": "Pulley rope high pull",
                            "reps": 15,
                            "sets": 3
                        }
                    }]
            }
         ]
}]
}

"""
    }
}
