// F1-optimal confidence thresholds per bone-part model.
// A scan is classified as abnormal when confidence >= threshold.
const Map<String, double> boneConfidenceThresholds = {
    'WRIST':    0.2476 ,
    'HUMERUS':  0.0793,
    'ELBOW':    0.2674,
    'FOREARM':  0.0892,
    'FINGER':   0.1981,
    'HAND':     0.0397,
    'SHOULDER': 0.3070,
};
/// Returns the threshold for [bonePart] (case-insensitive), or null if unknown.
double? thresholdFor(String? bonePart) =>
    bonePart == null ? null : boneConfidenceThresholds[bonePart.toUpperCase()];
