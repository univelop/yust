import 'package:coordinate_converter/coordinate_converter.dart';

import '../../yust.dart';

/// Enum for the four cardinal directions.
enum YustCardinalDirection {
  north,
  south,
  east,
  west;

  /// Returns the [DirectionY] equivalent of the [YustCardinalDirection].
  DirectionX toDirectionX() {
    switch (this) {
      case YustCardinalDirection.east:
        return DirectionX.east;
      case YustCardinalDirection.west:
        return DirectionX.west;
      default:
        throw YustException(
          'Invalid cardinal direction. Expected YustCardinalDirection.east or YustCardinalDirection.west',
        );
    }
  }

  /// Returns the [DirectionY] equivalent of the [YustCardinalDirection].
  DirectionY toDirectionY() {
    switch (this) {
      case YustCardinalDirection.north:
        return DirectionY.north;
      case YustCardinalDirection.south:
        return DirectionY.south;
      default:
        throw YustException(
          'Invalid cardinal direction. Expected YustCardinalDirection.north or YustCardinalDirection.south',
        );
    }
  }

  /// Returns the [YustCardinalDirection] equivalent of the [DirectionX].
  factory YustCardinalDirection.fromDirectionX(DirectionX direction) {
    switch (direction) {
      case DirectionX.east:
        return YustCardinalDirection.east;
      case DirectionX.west:
        return YustCardinalDirection.west;
    }
  }

  /// Returns the [YustCardinalDirection] equivalent of the [DirectionY].
  factory YustCardinalDirection.fromDirectionY(DirectionY direction) {
    switch (direction) {
      case DirectionY.north:
        return YustCardinalDirection.north;
      case DirectionY.south:
        return YustCardinalDirection.south;
    }
  }
}
