#!/usr/bin/perl -w
# Author: William Lam; Tim Lapawa
# Website: www.virtuallyghetto.com
# Reference: http://www.virtuallyghetto.com/2011/12/retrieving-information-from-distributed.html

use strict;
use warnings;
use VMware::VIRuntime;
use VMware::VILib;
use Term::ANSIColor;

my %opts = (
        'list' => {
        type => "=s",
        help => "Operation [all|summary|config|networkpool|portgroup|host|vm|health]",
        required => 1,
        },
        'dvswitch' => {
        type => "=s",
        help => "Name of dvSwitch",
        required => 0,
        },
);
# validate options, and connect to the server
Opts::add_options(%opts);

# validate options, and connect to the server
Opts::parse();
Opts::validate();
my $vim = Util::connect();

my $list = Opts::get_option('list');
my $dvswitch = Opts::get_option('dvswitch');
my $dvSwitches;
my $sc = $vim->get_service_content();
my $apiVersion = $sc->about->version;

print ("vCenterServer: ".color("yellow"). $vim->{service_url}. color('reset').' - '. color('yellow'). $sc->about->fullName . color("reset"). "\n");

my $dvSwitchProperties = {};
if ($list eq 'health') {
    $dvSwitchProperties = [ 'name', 'runtime', 'config.host', 'config.healthCheckConfig' ];
}

if($dvswitch) {
    $dvSwitches = Vim::find_entity_views(view_type => 'DistributedVirtualSwitch'
                                        , filter => {'name' => $dvswitch}
                                        , properties => $dvSwitchProperties
                                        );
} else {
    $dvSwitches = Vim::find_entity_views(view_type => 'DistributedVirtualSwitch'
                                        , properties => $dvSwitchProperties
                                        );
}

foreach my $dvs (sort{$a->name cmp $b->name} @$dvSwitches) {
	print 'dvSwitch: '.color("yellow") . $dvs->name . "\n" . color("reset");
	if($list eq "all" || $list eq "summary") {
		print "UUID: " . color("cyan") . $dvs->summary->uuid . "\n" . color("reset");
		print "Description: " . color("cyan") . ($dvs->summary->description ? $dvs->summary->description : "N/A") . "\n" . color("reset");
		print "NumPorts: " . color("cyan") . $dvs->summary->numPorts . "\n" . color("reset");
		if($dvs->summary->productInfo) {
			print "ProductInfo: " . color("cyan") . ($dvs->summary->productInfo->vendor ? $dvs->summary->productInfo->vendor : "") . " " . ($dvs->summary->productInfo->name ? $dvs->summary->productInfo->name : "") . " " . ($dvs->summary->productInfo->version ? $dvs->summary->productInfo->version : "") . "\n" . color("reset");
		}
		if($dvs->summary->contact) {
			print "Contact: " . color("cyan") . ($dvs->summary->contact->name ? $dvs->summary->contact->name : "") . " " . ($dvs->summary->contact->contact ? $dvs->summary->contact->contact: "") . "\n" . color("reset");
		}
		if($dvs->summary->hostMember) {
			my $hostMembers = $dvs->summary->hostMember;
			print "Host(s): " . color("cyan") . scalar(@$hostMembers) . "\n" . color("reset");
		}
		if($dvs->summary->vm) {
			my $vms = $dvs->summary->vm;
			print "VirtualMacine(s): " . color("cyan") . scalar(@$vms) . "\n" . color("reset");
		}
		if($dvs->summary->portgroupName) {
                        my $portgroupNames = $dvs->summary->portgroupName;
                        print "dvPortgroup(s): " . color("cyan") . scalar(@$portgroupNames) . "\n" . color("reset");
                }
		print "\n";
	}
	if($list eq "all" || $list eq "config") {
		print "ConfigVersion: " . color("green") . $dvs->config->configVersion . "\n" . color("reset");
		print "CreateTime: " . color("green") . $dvs->config->createTime . "\n" . color("reset");
		if($apiVersion eq "5.0.0") {
			print "SwitchIPAddress: " . color("green") . ($dvs->config->switchIpAddress ? $dvs->config->switchIpAddress : "N/A") . "\n" . color("reset");
		}
		print "NumPorts: " . color("green") . $dvs->config->numPorts . "\n" . color("reset");
		print "NumStandalonePorts: " . color("green") . $dvs->config->numStandalonePorts . "\n" . color("reset");
		print "MaxPorts: " . color("green") . $dvs->config->maxPorts . "\n" . color("reset");
		if($dvs->config->isa("VMwareDVSConfigInfo")) {
			print "MaxMTU: " . color("green") . $dvs->config->maxMtu . "\n" . color("reset");
			if($dvs->config->linkDiscoveryProtocolConfig) {
                                print "LDPOperation: " . color("green") . $dvs->config->linkDiscoveryProtocolConfig->operation . "\n" . color("reset");
                                print "LDPProtocol: " . color("green") . $dvs->config->linkDiscoveryProtocolConfig->protocol . "\n" . color("reset");
                        }
		}
		print "NetworkResourceMgmtEnable: " . color("green") . ($dvs->config->networkResourceManagementEnabled ? "true" : "false") . "\n" . color("reset");
		if($apiVersion eq "5.0.0" && $dvs->config->defaultPortConfig->isa("VMwareDVSPortSetting")) {
			if(defined($dvs->config->defaultPortConfig->ipfixEnabled->value)) {
	                	print "ipfixEnabled: " . color("green") . ($dvs->config->defaultPortConfig->ipfixEnabled->value ? "true" : "false") . "\n" . color("reset");
			}
			if($dvs->config->defaultPortConfig->securityPolicy) {
				print "\n";
				if(defined($dvs->config->defaultPortConfig->securityPolicy->allowPromiscuous->value)) {
					print "AllowPromo: " . color("green") . ($dvs->config->defaultPortConfig->securityPolicy->allowPromiscuous->value ? "true" : "false") . "\n" . color("reset");
				}
				if(defined($dvs->config->defaultPortConfig->securityPolicy->forgedTransmits->value)) {
					print "ForgeTransmits: " . color("green") . ($dvs->config->defaultPortConfig->securityPolicy->forgedTransmits->value ? "true" : "false") . "\n" . color("reset");
				}
				if(defined($dvs->config->defaultPortConfig->securityPolicy->macChanges->value)) {
					print "MacChanges: " . color("green") . ($dvs->config->defaultPortConfig->securityPolicy->macChanges->value ? "true" : "false") . "\n" . color("reset");
				}
				if($dvs->config->defaultPortConfig->inShapingPolicy) {
					if(defined($dvs->config->defaultPortConfig->inShapingPolicy->enabled->value)) {
						print "\ninShapingEnabled: " . color("green") . ($dvs->config->defaultPortConfig->inShapingPolicy->enabled->value ? "true" : "false") . "\n" . color("reset");
					}
					if(defined($dvs->config->defaultPortConfig->inShapingPolicy->averageBandwidth->value)) {
                                                print "inShapingAvgBW: " . color("green") . ($dvs->config->defaultPortConfig->inShapingPolicy->averageBandwidth->value ? $dvs->config->defaultPortConfig->inShapingPolicy->averageBandwidth->value : "N/A") . "\n" . color("reset");
                                        }
					if(defined($dvs->config->defaultPortConfig->inShapingPolicy->peakBandwidth->value)) {
                                                print "inShapingPeakBW: " . color("green") . ($dvs->config->defaultPortConfig->inShapingPolicy->peakBandwidth->value ? $dvs->config->defaultPortConfig->inShapingPolicy->peakBandwidth->value : "N/A") . "\n" . color("reset");
                                        }
					if(defined($dvs->config->defaultPortConfig->inShapingPolicy->burstSize->value)) {
                                                print "inShapingBurstSize: " . color("green") . ($dvs->config->defaultPortConfig->inShapingPolicy->burstSize->value ? $dvs->config->defaultPortConfig->inShapingPolicy->burstSize->value : "N/A") . "\n" . color("reset");
                                        }
				}
				if($dvs->config->defaultPortConfig->outShapingPolicy) {
					if(defined($dvs->config->defaultPortConfig->outShapingPolicy->enabled->value)) {
                                                print "\noutShapingEnabled: " . color("green") . ($dvs->config->defaultPortConfig->outShapingPolicy->enabled->value ? "true" : "false") . "\n" . color("reset");
                                        }
                                        if(defined($dvs->config->defaultPortConfig->outShapingPolicy->averageBandwidth->value)) {
                                                print "outShapingAvgBW: " . color("green") . ($dvs->config->defaultPortConfig->outShapingPolicy->averageBandwidth->value ? $dvs->config->defaultPortConfig->outShapingPolicy->averageBandwidth->value : "N/A") . "\n" . color("reset");
                                        }
                                        if(defined($dvs->config->defaultPortConfig->outShapingPolicy->peakBandwidth->value)) {
                                                print "outShapingPeakBW: " . color("green") . ($dvs->config->defaultPortConfig->outShapingPolicy->peakBandwidth->value ? $dvs->config->defaultPortConfig->outShapingPolicy->peakBandwidth->value : "N/A") . "\n" . color("reset");
                                        }
                                        if(defined($dvs->config->defaultPortConfig->outShapingPolicy->burstSize->value)) {
                                                print "outShapingBurstSize: " . color("green") . ($dvs->config->defaultPortConfig->outShapingPolicy->burstSize->value ? $dvs->config->defaultPortConfig->outShapingPolicy->burstSize->value : "N/A") . "\n" . color("reset");
                                        }
                                }
			}
		}
		if($dvs->config->isa("VMwareDVSConfigInfo")) {
			if($apiVersion eq "5.0.0" && $dvs->config->ipfixConfig) {
				print "\nCollectorIpAddress: " . color("green") . ($dvs->config->ipfixConfig->collectorIpAddress ? $dvs->config->ipfixConfig->collectorIpAddress : "N/A") . "\n" . color("reset"); 
				print "CollectorPort: " . color("green") . ($dvs->config->ipfixConfig->collectorPort ? $dvs->config->ipfixConfig->collectorPort : "N/A") . "\n" . color("reset");
				print "ActiveFlowTimeout: " . color("green") . $dvs->config->ipfixConfig->activeFlowTimeout . "\n" . color("reset");
				print "IdleFlowTimeout: " . color("green") . $dvs->config->ipfixConfig->idleFlowTimeout . "\n" . color("reset");
				print "InternalFlowsOnly: " . color("green") . ($dvs->config->ipfixConfig->internalFlowsOnly ? "true" : "false") . "\n" . color("reset");
				print "SamplingRate: " . color("green") . $dvs->config->ipfixConfig->samplingRate . "\n" . color("reset");
			}
			if($dvs->config->pvlanConfig) {
                                my $pvlans = $dvs->config->pvlanConfig;
                                print "\n";
                                foreach my $pvlan (@$pvlans) {
                                        print "PVLANPrimID: " . color("green") . $pvlan->primaryVlanId . color("reset") . " PVLANSecondaryId: " . color("green") . $pvlan->secondaryVlanId . color("reset") . " PVLANType: " . color("green") . $pvlan->pvlanType . "\n" . color("reset"); 
                                }
                        }
			if($apiVersion eq "5.0.0" && $dvs->config->vspanSession) {
				my $vspans = $dvs->config->vspanSession;
				print "\n";
				foreach my $vspan (@$vspans) {
					print "vSpanName: " . color("green") . ($vspan->name ? $vspan->name : "N/A") . "\n" . color("reset");
					print "vSpanEnabled: " . color("green") . ($vspan->enabled ? "true" : "false") . "\n" . color("reset");
					print "vSpanAllowNormalIODstPort: " . color("green") . ($vspan->normalTrafficAllowed ? "true" : "false") . "\n" . color("reset");
					print "vSpanEncapVLAN: " . color("green") . ($vspan->encapsulationVlanId ? $vspan->encapsulationVlanId : "N/A") . "\n" . color("reset");
					print "vSpanPreserveOrgVLAN: " . color("green") . ($vspan->stripOriginalVlan ? "false" : "true") . "\n" . color("reset");
					print "vSpanMirrorPacketLen: " . color("green") . ($vspan->mirroredPacketLength ? $vspan->mirroredPacketLength : "N/A") . "\n" . color("reset");
					if($vspan->sourcePortReceived->portKey) {
						my $vspanSrcIngresPorts = "";
						my $portKeys = $vspan->sourcePortReceived->portKey;
						foreach (@$portKeys) { $vspanSrcIngresPorts .= $_ . " "; }
						print "vSpanMirrorPortSRCIngress: " . color("green") . $vspanSrcIngresPorts . "\n" . color("reset");
					}
					if($vspan->sourcePortTransmitted->portKey) {
						my $vspanSrcEgressPorts = "";
						my $portKeys = $vspan->sourcePortTransmitted->portKey;
						foreach (@$portKeys) { $vspanSrcEgressPorts .= $_ . " "; }
						print "vSpanMirrorPortSRCEgress: " . color("green") . $vspanSrcEgressPorts . "\n" . color("reset");
					}
					if($vspan->destinationPort) {
						if($vspan->destinationPort->portKey) {
							my $vspanDstPorts = "";
							my $portKeys = $vspan->destinationPort->portKey;
							foreach (@$portKeys) { $vspanDstPorts .= $_ . " "; } 
							print "vSpanMirrorPortDST: " . color("green") . $vspanDstPorts . "\n" . color("reset");
						}
						if($vspan->destinationPort->uplinkPortName) {
							my $vspanDstUplinks = "";
							my $uplinkKeys = $vspan->destinationPort->uplinkPortName;
							foreach (@$uplinkKeys) { $vspanDstUplinks .= $_ . " "; }
							print "vSpanMirrorUplinkDST: " . color("green") . $vspanDstUplinks . "\n" . color("reset");
						}
					}
					print "\n";
				}
			}
		}
	}
	if($list eq "all" || $list eq "networkpool") {
		if($dvs->networkResourcePool) {
			my $netPools = $dvs->networkResourcePool;
			print "\n";
			foreach my $netPool (@$netPools) {
				print "NetPoolName: " . color("red") . ($netPool->name ? $netPool->name : "N/A") . "\n" . color("reset");
				print "NetPoolDescription: " . color("red") . ($netPool->description ? $netPool->description : "N/A") . "\n" . color("reset");
				if(defined($netPool->allocationInfo->limit)) {
					print "NetPoolLimit: " . color("red") . $netPool->allocationInfo->limit . "\n" . color("reset");
				}
				if(defined($netPool->allocationInfo->shares)) {
					print "NetPoolShares: " . color("red") . $netPool->allocationInfo->shares->shares . "\n" . color("reset");
					print "NetPoolSharesLevel: " . color("red") . $netPool->allocationInfo->shares->level->val . "\n" . color("reset");
				}
				if($apiVersion eq "5.0.0" && defined($netPool->allocationInfo->priorityTag)) {
					print "NetPoolPriorityTag: " . color("red") . $netPool->allocationInfo->priorityTag . "\n" . color("reset");
				}
				print "\n";
			}
		}
	}
	if($list eq "all" || $list eq "portgroup") {
		if($dvs->portgroup) {
			my $dvPortgroups = $dvs->portgroup;
			foreach my $dvPortgroup (@$dvPortgroups) {
				my $dvPortgroupView = Vim::get_view(mo_ref => $dvPortgroup);
				print "dvPortgroupName: " . color("magenta") . $dvPortgroupView->config->name . "\n" . color("reset");
				print "dvPortgroupDescription: " . color("magenta") . ($dvPortgroupView->config->description ? $dvPortgroupView->config->description : "N/A") . "\n" . color("reset");
				if($dvPortgroupView->config->distributedVirtualSwitch) {
					my $dvPortgroupdvswitch = Vim::get_view(mo_ref => $dvPortgroupView->config->distributedVirtualSwitch, properties => ['name']);
					print "dvPortgroupdvSwitch: " . color("magenta") . $dvPortgroupdvswitch->{'name'} . "\n" . color("reset");
				}
				if($dvPortgroupView->config->defaultPortConfig->vlan->vlanId) {
					my $dvPgVlan = "";
					if($dvPortgroupView->config->defaultPortConfig->vlan->isa("VmwareDistributedVirtualSwitchTrunkVlanSpec")) {
						my $vlans = $dvPortgroupView->config->defaultPortConfig->vlan->vlanId;
						foreach (@$vlans) {
							$dvPgVlan .= $_->start . "-" . $_->end . " ";
						}	
					} elsif($dvPortgroupView->config->defaultPortConfig->vlan->isa("VmwareDistributedVirtualSwitchPvlanSpec")) {
						$dvPgVlan = $dvPortgroupView->config->defaultPortConfig->vlan->pvlanId;
					} elsif($dvPortgroupView->config->defaultPortConfig->vlan->isa("VmwareDistributedVirtualSwitchVlanIdSpec")) {
						$dvPgVlan = $dvPortgroupView->config->defaultPortConfig->vlan->vlanId;
					} else {
						$dvPgVlan = "N/A";
					}
					print "dvPortgroupVlan: " . color("magenta") . $dvPgVlan . "\n" . color("reset");
				}
				print "dvPortgroupKey: " . color("magenta") . $dvPortgroupView->config->key . "\n" . color("reset");
				print "dvPortgroupVersion: " . color("magenta") . ($dvPortgroupView->config->configVersion ? $dvPortgroupView->config->configVersion : "N/A") . "\n" . color("reset");
				print "dvPortgroupNumPorts: " . color("magenta") . $dvPortgroupView->config->numPorts . "\n" . color("reset");
				print "dvPortgroupType: " . color("magenta") . $dvPortgroupView->config->type . "\n" . color("reset");
				if($dvPortgroupView->config->defaultPortConfig->securityPolicy) {
					if($dvPortgroupView->config->defaultPortConfig->securityPolicy->isa("InheritablePolicy")) {
						print "Security Inhereited: " . color("magenta") . ($dvPortgroupView->config->defaultPortConfig->securityPolicy->inherited ? "true" : "false") . "\n" . color("reset");
					}
					if(defined($dvPortgroupView->config->defaultPortConfig->securityPolicy->allowPromiscuous->value)) {
              	                          print "AllowPromo: " . color("magenta") . ($dvPortgroupView->config->defaultPortConfig->securityPolicy->allowPromiscuous->value ? "true" : "false") . "\n" . color("reset");
                                	}
                	                if(defined($dvPortgroupView->config->defaultPortConfig->securityPolicy->forgedTransmits->value)) {
                        	                print "ForgeTransmits: " . color("magenta") . ($dvPortgroupView->config->defaultPortConfig->securityPolicy->forgedTransmits->value ? "true" : "false") . "\n" . color("reset");
                                	}
	                                if(defined($dvPortgroupView->config->defaultPortConfig->securityPolicy->macChanges->value)) {
        	                                print "MacChanges: " . color("magenta") . ($dvPortgroupView->config->defaultPortConfig->securityPolicy->macChanges->value ? "true" : "false") . "\n" . color("reset");
                	                }	
				}
				print "\n";
			}
		}
	}
	if($list eq "all" || $list eq "host" || $list eq "vm") {
		my %dvportGroupMapping = ();
		if($dvs->portgroup) {
                        my $dvPortgroups = $dvs->portgroup;
                        foreach my $dvPortgroup (@$dvPortgroups) {
                                my $dvPortgroupView = Vim::get_view(mo_ref => $dvPortgroup, properties => ['name','key']);
				$dvportGroupMapping{$dvPortgroupView->{'key'}} = $dvPortgroupView->{'name'};
			}
		}

		eval {
			my $vmCriteria = DistributedVirtualSwitchPortCriteria->new(connected => 'true');
			my $dvports = $dvs->FetchDVPorts(criteria => $vmCriteria);
			foreach my $dvport (@$dvports) {
				if($dvport->connectee) {
					if($list eq "vm" && $dvport->connectee && $dvport->connectee->connectedEntity->type eq "VirtualMachine") {
						my $connecteeView = Vim::get_view(mo_ref => $dvport->connectee->connectedEntity, properties => ['name']);
                                                print "VM: " . color("yellow") . $connecteeView->{'name'} . " " . color("reset");
						print "dvPortgroup: " . color("yellow") . $dvportGroupMapping{$dvport->portgroupKey} . " " . color("reset");
						print "Device: " . color("yellow") . ($dvport->connectee->nicKey ? $dvport->connectee->nicKey : "") . " " . color("reset"); 
						print "Status: " . color("yellow") . (defined($dvport->state->runtimeInfo->linkUp) ? ($dvport->state->runtimeInfo->linkUp ? "up" : "down") : "N/A") . " " . color("reset");
						print "PortId: " . color("yellow") . $dvport->key . "\n" . color("reset");
					} elsif($list eq "host" && $dvport->connectee && $dvport->connectee->connectedEntity->type eq "HostSystem") {
						my $connecteeView = Vim::get_view(mo_ref => $dvport->connectee->connectedEntity, properties => ['name']);
						print "Host: " . color("yellow") . $connecteeView->{'name'} . " " . color("reset");
                                                print "dvPortgroup: " . color("yellow") . $dvportGroupMapping{$dvport->portgroupKey} . " " . color("reset");
                                                print "Device: " . color("yellow") . ($dvport->connectee->nicKey ? $dvport->connectee->nicKey : "") . " " . color("reset");
                                                print "Status: " . color("yellow") . (defined($dvport->state->runtimeInfo->linkUp) ? ($dvport->state->runtimeInfo->linkUp ? "up" : "down") : "N/A") . " " . color("reset");
                                                print "PortId: " . color("yellow") . $dvport->key . "\n" . color("reset");
					}
				}
			}
		};
		if($@) {
			print "ERROR: Unable to query for entities connected to dvSwitch " . $@ . "\n";
		}
	}
	if($list eq "all" || $list eq "health") {
    #  * dvSwitch->runtime->hostMemberRuntime[]
    #    - lists all hosts of dvSwitch
    #  *
        my $hostMemberRuntimeInfo = $dvs->{runtime}->{hostMemberRuntime};
        my %r = ();
#        print "  Check NIC Infos for host: \t'".$host->name."'\n\n";
        format STDOUT =
 @<<<<<<<<<<<<<<<<<<<<<<<<<<< |@<<<<<< |@<<<<<<<<<<<<<<<<<<<<<<<<<... |@<<<<<<<<<<<<<<< |@<<<<<<<<<<<<<<<<<< |@*
 $r{host},                     $r{pnic}, $r{switch},                   $r{address},     $r{port},             $r{missingvlans}
.
        my $foundHealthCheckResults = undef;
        foreach my $hostMember (@{$hostMemberRuntimeInfo}) {
            if ( exists $hostMember->{healthCheckResult}) {

                my $hostRef = $hostMember->{host};
                my $hostView =  Vim::get_view( mo_ref => $hostRef, properties => [ 'name', 'configManager'] );

                if ($hostMember->status ne 'up') {
                    print ("\n".$hostView->name.color("red") . 'DOWN'.color('reset'));
                    next;
                }
                
                if ($hostView->name eq 'ffm30vmwzst0112.mhs.msys.net') {
                    print 'found it';
                }
                
                
                my $netMgr = undef;
                my $checkResults = $hostMember->{healthCheckResult};
                foreach my $checkResult (@{$checkResults}){
                    if ( ref($checkResult) eq 'VMwareDVSVlanHealthCheckResult') {
                        %r = (
                            host         => $hostView->name,
                            pnic         => '',
                            switch       => '',
                            address      => '',
                            port         => '',
                            missingvlans => '',
                        );

                        # find physical uplink for DVS uplinkPort
                        #    dvs-83&doPath=config.host
                        #
                        my $dvsHostMembers = $dvs->{'config.host'};
                        $netMgr ||= Vim::get_view(mo_ref => $hostView->configManager->networkSystem);
                        foreach my $member (@{$dvsHostMembers}){
                            my $dvsConfigHostrefValue = $member->{config}->{host}->{value};
                            if ($hostRef->{value} eq $dvsConfigHostrefValue) {
                                my $pnicSpecs = $member->{config}->{backing}->{pnicSpec};
                                foreach my $pnic (@{$pnicSpecs}){
                                    if ($pnic->{uplinkPortKey} eq $checkResult->{uplinkPortKey}) {
                                        $r{pnic} = $pnic->{pnicDevice};
                                    }
                                }
                            }
                        }
                        
                        #
                        # find CDP infos for pnic and host
                        #
                        my @physicalNicHintInfo = $netMgr->QueryNetworkHint();
                        foreach (@physicalNicHintInfo) {
                            foreach ( @{$_} ) {
                                next if ($r{pnic} ne $_->device);  # skip wrong device
                                if(defined($_->connectedSwitchPort)) {
                                    $r{switch}  = $_->connectedSwitchPort->devId;
                                    $r{address} = $_->connectedSwitchPort->address;
                                    $r{port}    = $_->connectedSwitchPort->portId;
                                }
                            }
                        }
                        my $untrunkedVlans =  $checkResult->{untrunkedVlan};
                        my %missingVlans = ();
                        foreach my $untrunkedVlan (@{$untrunkedVlans}){
                            my $start = int($untrunkedVlan->{start});
                            my $end   = int($untrunkedVlan->{end});
                            if ( $start eq $end ) {
                                $missingVlans{$start} = 1;
                            } else {
                                for (my $i = $start; $i <= $end; $i++){ 
                                    $missingVlans{$i} = 1;
                                }
                            }
                        }
                        my @sorted = sort {$a <=> $b} keys %missingVlans;;
                        $r{missingvlans} = join (',', @sorted);
                        if (!$foundHealthCheckResults) {
                                                                                                       
                            print "  Host                        | pnic   | switch                       | address         | port               | missing VLANs          \n";
                            print " -----------------------------+--------+------------------------------+-----------------+--------------------+------------------------\n";
                        }
                        $foundHealthCheckResults ||= $hostMember;
                        write;
                    } # foreach VMwareDVSVlanHealthCheckResult
                } # foreach healthCheckResult
            } # if healthCheckResult 
        } # foreach $hostMemberRuntimeInfo
        
        if ( ! $foundHealthCheckResults ) {
            my $checkConfigs = $dvs->{'config.healthCheckConfig'};
            if ( lc ($checkConfigs->[0]->{'enable'}) ) {
                print '** Could not find any DVSwitch Health check results.'.color('red').' Please reconfigure health check to get new results.'.color('reset');
            } else {
                print '** DVSwitch Health check is deactivated. '.color('red').'Please enable and rerun script to collect results.'.color('reset');
            }
        }
        print "\n";
    } # if --list all|health
} # foreach @$dvSwitches
if (!scalar @{ $dvSwitches}) {
    print "WARN: Could not find dvSwitch: '".$dvswitch."' with service url '".$vim->{service_url}."'. DONE!";
}


Util::disconnect();
