## [Unreleased]

## [1.2.0] - 2019-10-19
### Added
- Add `:ttl` option for `memoize` method ([@AlexWayfer]) [#11]
- Add benchmark script ([@AlexWayfer]) [#14]
- Add `.memoized?` method ([@AlexWayfer]) [#17]

## [1.1.0] - 2019-08-05
### Fixed
- Optimize speed and memory for cached values returns. ([@AlexWayfer]) [#10]

## [1.0.0] - 2018-08-31
### Added
- Add `:condition` option for `.memoize` method. ([@AlexWayfer]) [#7]

## [0.6.0] - 2018-04-20
### Added
- Readme example for memoizing class methods. ([@AlexWayfer]) [#3]
- Memery raises `ArgumentError` if method is not defined when you call `memoize`.

## [0.5.0] - 2017-16-12
- Initial public version.

[0.5.0]: https://github.com/tycooon/memery/tree/v0.5.0
[0.6.0]: https://github.com/tycooon/memery/compare/v0.5.0...v0.6.0
[1.0.0]: https://github.com/tycooon/memery/compare/v0.6.0...v1.0.0
[1.1.0]: https://github.com/tycooon/memery/compare/v1.0.0...v1.1.0
[1.2.0]: https://github.com/tycooon/memery/compare/v1.1.0...v1.2.0
[Unreleased]: https://github.com/tycooon/memery/compare/v1.2.0...HEAD

[@tycooon]: https://github.com/tycooon
[@AlexWayfer]: https://github.com/AlexWayfer

[#3]: https://github.com/tycooon/memery/pull/3
[#7]: https://github.com/tycooon/memery/pull/7
[#10]: https://github.com/tycooon/memery/pull/10
[#11]: https://github.com/tycooon/memery/pull/11
[#14]: https://github.com/tycooon/memery/pull/14
[#17]: https://github.com/tycooon/memery/pull/17
