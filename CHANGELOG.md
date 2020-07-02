# Changelog

All notable changes to this project will be documented in this file.

The format is mainly based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

* Added: New command to invoke a database copy
* Added: Add edition to the Test-SqlConnection command
* Fixed: Connection string not in result object
* Fixed: Prevent the password leaking in an exception message

## 0.2.0 - 2020-05-17

* Changed: Add quiet option for Test-SqlConnection command
* Fixed: Wrap error for missing SERVER STATE PERMISSIONS in Test-SqlConnection

## 0.1.0 - 2020-03-05

* Added: Initial release with just Test-SqlConnection command
