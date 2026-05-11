// F1-optimal confidence thresholds per bone-part model.
// A scan is classified as abnormal when confidence >= threshold.
const Map<String, double> boneConfidenceThresholds = {
    'WRIST':    0.2088 ,
    'HUMERUS':  0.0829,
    'ELBOW':    0.3047,
    'FOREARM':  0.2977,
    'FINGER':   0.2058,
    'HAND':     0.0390,
    'SHOULDER': 0.2907,
};
/// Returns the threshold for [bonePart] (case-insensitive), or null if unknown.
double? thresholdFor(String? bonePart) =>
    bonePart == null ? null : boneConfidenceThresholds[bonePart.toUpperCase()];
