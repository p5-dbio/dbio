package DBIO::DeploymentHandler::HandlesVersionStorage;
# ABSTRACT: Interface for version storage methods

use strict;
use warnings;

# This is an interface - implementing classes must provide:
#   add_database_version
#   database_version
#   delete_database_version
#   version_storage_is_installed

1;

# vim: ts=2 sw=2 expandtab