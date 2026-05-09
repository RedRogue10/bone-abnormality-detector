// F1-optimal confidence thresholds per bone-part model.
// A scan is classified as abnormal when confidence >= threshold.
const Map<String, double> boneConfidenceThresholds =  {
    'WRIST':    0.1359,
    'HUMERUS':  0.2118,
    'ELBOW':    0.2408 ,
    'FOREARM':  0.1748,
    'FINGER':   0.0300,
    'HAND':     0.0250,
    'SHOULDER': 0.2268,
};
/// Returns the threshold for [bonePart] (case-insensitive), or null if unknown.
double? thresholdFor(String? bonePart) =>
    bonePart == null ? null : boneConfidenceThresholds[bonePart.toUpperCase()];
