## 1.6.1 - 2021-02-22

* Improve mapToJson

## 1.6.0 - 2021-02-19

* Improve date time handling
* Add offline check
* Improve yust doc

Breaking changes:
* `YustDoc.mapFromJson` returs DateTime values instead of Timestamp values.
* Therefore `YustDoc.mapToJson` transfers DateTime values to Timestamps.

## 1.5.0 - 2021-02-19

* Add time picker
* Add input tile
* Migrate to Flutter 1.12
* Improve reset password
* Improve image picker
* Improve resize image
* Improve text field
* Improve map from json
* Improve modal buttons
* Usability improvements
* Fix bugs

## 1.4.0 - 2020-11-14

* Add image handling for web
* Add multiple image picking
* Add file picker
* Improve authentication
* Add file download
* Add file exisit check
* Fix bugs

## 1.3.0 - 2020-09-24

* Update firebase
* Add image picker
* Improve number field

## 1.2.2 - 2020-09-11

* Fix widget overflows

## 1.2.1 - 2020-09-08

* Improve serialization

## 1.2.0 - 2020-09-07

* Add onEditingComplete to widgets
* Improve store builder

## 1.1.0 - 2020-09-01

* Add prefix icon to widgets

## 1.0.1 - 2020-08-20

* Improve switch

## 1.0.0 - 2020-08-01

* Add created by, modified at, modified by
* Improve number field
* Improve authentication
* Improve widgets

## 0.5.0 - 2020-06-05

* Improve authentication
* Improve filtering
* Improve user subscriber
* Support Flutter Web
* Support Firestore timestamps:
  Set `useTimestamps` in `Yust.initialize` to `true`
* Improve JSON Serialization
* Add useful widgets
* Add documentation
* Fix issues

Breaking changes:
* `createdAt` in YustDoc changed type from String to DateTime.
* Use `formatDate` and `formatTime` in YustService if you switch to Firebase timestamps. Use `formatIsoDate` and `formatIsoTime` for the old ISO Datetime format.

## 0.4.0 - 2020-01-17

* Update to Flutter 1.12
* Add insights to doc builder
* Improve date picker
* Improve push notifications
* Enable offline persistance
* Improve sign in and sign up
* Improve routing
* Make user extendable
* Improve descanding ordering

## 0.3.0 - 2019-10-25

* Improve doc builder
* Add sorting for queries
* Add getDocOnce and getDocsOnce queries
* Add switch tile widget
* Add notifications and badges
* Add progress button
* Add account edit screen
* Use firebase document merging
* Improvements and hotfixes

## 0.2.0 - 2019-07-31

* Improve filters
* Add random string generator
* Add account screen
* Improvements and hotfixes

## 0.1.0 - 2019-07-23

* Initial release
* Firebase Authentication
* Firestore load and save services
* Widgets to handle firebase requests
