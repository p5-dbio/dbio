package DBIO::DeploymentHandler::HandlesDeploy;
# ABSTRACT: Interface for deploy methods

use strict;
use warnings;

# This is an interface role - implementing classes must provide:
#   initialize
#   prepare_deploy, deploy
#   prepare_resultsource_install, install_resultsource
#   prepare_upgrade, upgrade_single_step
#   prepare_downgrade, downgrade_single_step
#   txn_do

1;

# vim: ts=2 sw=2 expandtab