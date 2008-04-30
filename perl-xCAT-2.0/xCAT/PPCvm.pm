# IBM(c) 2007 EPL license http://www.eclipse.org/legal/epl-v10.html

package xCAT::PPCvm;
use strict;
use Getopt::Long;
use xCAT::PPCcli qw(SUCCESS EXPECT_ERROR RC_ERROR NR_ERROR);
use xCAT::PPCdb;
use xCAT::Usage;
use xCAT::NodeRange;


##############################################
# Globals
##############################################
my %method = (
    mkvm => \&mkvm_parse_args,
    lsvm => \&lsvm_parse_args,
    rmvm => \&rmvm_parse_args, 
    chvm => \&chvm_parse_args 
);


##########################################################################
# Parse the command line for options and operands
##########################################################################
sub parse_args {

    my $request = shift;
    my $cmd     = $request->{command};

    ###############################
    # Invoke correct parse_args 
    ###############################
    my $result = $method{$cmd}( $request );
    return( $result ); 
}


##########################################################################
# Parse the chvm command line for options and operands
##########################################################################
sub chvm_parse_args {

    my $request = shift;
    my %opt     = ();
    my $cmd     = $request->{command};
    my $args    = $request->{arg};

    #############################################
    # Responds with usage statement
    #############################################
    local *usage = sub {
        my $usage_string = xCAT::Usage->getUsage($cmd);
        return( [ $_[0], $usage_string] );
    };
    ####################################
    # Configuration file required 
    ####################################
    if ( !exists( $request->{stdin} ) ) {
        return(usage( "Configuration file not specified" ));
    }
    #############################################
    # Process command-line arguments
    #############################################
    if ( !defined( $args )) {
        $request->{method} = $cmd;
        return( \%opt );
    }
    #############################################
    # Checks case in GetOptions, allows opts
    # to be grouped (e.g. -vx), and terminates
    # at the first unrecognized option.
    #############################################
    @ARGV = @$args;
    $Getopt::Long::ignorecase = 0;
    Getopt::Long::Configure( "bundling" );

    if ( !GetOptions( \%opt, qw(V|Verbose) )) {
        return( usage() );
    }
    ####################################
    # Check for "-" with no option
    ####################################
    if ( grep(/^-$/, @ARGV )) {
        return(usage( "Missing option: -" ));
    }
    ####################################
    # Check for an extra argument
    ####################################
    if ( defined( $ARGV[0] )) {
        return(usage( "Invalid Argument: $ARGV[0]" ));
    }
    ####################################
    # No operands - add command name 
    ####################################
    $request->{method} = $cmd;
    return( \%opt );
}


##########################################################################
# Parse the mkvm command line for options and operands
##########################################################################
sub mkvm_parse_args {

    my $request = shift;
    my %opt     = ();
    my $cmd     = $request->{command};
    my $args    = $request->{arg};

    #############################################
    # Responds with usage statement
    #############################################
    local *usage = sub {
        my $usage_string = xCAT::Usage->getUsage($cmd);
        return( [ $_[0], $usage_string] );
    };
    #############################################
    # Process command-line arguments
    #############################################
    if ( !defined( $args )) {
        return(usage( "No command specified" ));
    }
    #############################################
    # Only 1 node allowed 
    #############################################
    if ( scalar( @{$request->{node}} ) > 1) {
        return(usage( "multiple nodes specified" ));
    } 
    #############################################
    # Checks case in GetOptions, allows opts
    # to be grouped (e.g. -vx), and terminates
    # at the first unrecognized option.
    #############################################
    @ARGV = @$args;
    $Getopt::Long::ignorecase = 0;
    Getopt::Long::Configure( "bundling" );

    if ( !GetOptions( \%opt, qw(V|Verbose i=s n=s c=s) )) {
        return( usage() );
    }
    ####################################
    # Check for "-" with no option
    ####################################
    if ( grep(/^-$/, @ARGV )) {
        return(usage( "Missing option: -" ));
    }
    ####################################
    # Check for non-zero integer 
    ####################################
    if ( exists( $opt{i} )) {
        if ( $opt{i} !~ /^([1-9]{1}|[1-9]{1}[0-9]+)$/ ) {
            return(usage( "Invalid entry: $opt{i}" ));

        }
    }
    ####################################
    # -i and -n not valid with -c 
    ####################################
    if ( exists( $opt{c} ) ) {
        if ( exists($opt{i}) or exists($opt{n})) {
            return( usage() );
        }
    }
    ####################################
    # If -i and -n, both required
    ####################################
    elsif ( !exists($opt{n}) or !exists($opt{i})) {
        return( usage() );
    }
    ####################################
    # Check for an extra argument
    ####################################
    if ( defined( $ARGV[0] )) {
        return(usage( "Invalid Argument: $ARGV[0]" ));
    }
    ####################################
    # Expand -n noderange
    ####################################
    if ( exists( $opt{n} )) {
        my @noderange = xCAT::NodeRange::noderange( $opt{n},0 );
        if ( !defined( @noderange )) {
            return(usage( "Invalid noderange: '$opt{n}'" ));
        }
        $opt{n} = \@noderange;
    }
    ####################################
    # No operands - add command name 
    ####################################
    $request->{method} = $cmd;
    return( \%opt );
}



##########################################################################
# Parse the rmvm command line for options and operands
##########################################################################
sub rmvm_parse_args {

    my $request = shift;
    my %opt     = ();
    my $cmd     = $request->{command};
    my $args    = $request->{arg};

    #############################################
    # Responds with usage statement
    #############################################
    local *usage = sub { 
        my $usage_string = xCAT::Usage->getUsage($cmd);
        return( [ $_[0], $usage_string] );
    };
    #############################################
    # Process command-line arguments
    #############################################
    if ( !defined( $args )) {
        $request->{method} = $cmd;
        return( \%opt );
    }
    #############################################
    # Checks case in GetOptions, allows opts
    # to be grouped (e.g. -vx), and terminates
    # at the first unrecognized option.
    #############################################
    @ARGV = @$args;
    $Getopt::Long::ignorecase = 0;
    Getopt::Long::Configure( "bundling" );

    if ( !GetOptions( \%opt, qw(V|Verbose) )) {
        return( usage() );
    }
    ####################################
    # Check for "-" with no option
    ####################################
    if ( grep(/^-$/, @ARGV )) {
        return(usage( "Missing option: -" ));
    }
    ####################################
    # Check for an extra argument
    ####################################
    if ( defined( $ARGV[0] )) {
        return(usage( "Invalid Argument: $ARGV[0]" ));
    }
    ####################################
    # No operands - add command name 
    ####################################
    $request->{method} = $cmd; 
    return( \%opt );
}


##########################################################################
# Parse the lsvm command line for options and operands
##########################################################################
sub lsvm_parse_args {

    my $request = shift;
    my %opt     = ();
    my $cmd     = $request->{command};
    my $args    = $request->{arg};

    #############################################
    # Responds with usage statement
    #############################################
    local *usage = sub {
        my $usage_string = xCAT::Usage->getUsage($cmd);
        return( [ $_[0], $usage_string] );
    };
    #############################################
    # Process command-line arguments
    #############################################
    if ( !defined( $args )) {
        $request->{method} = $cmd;
        return( \%opt );
    }
    #############################################
    # Checks case in GetOptions, allows opts
    # to be grouped (e.g. -vx), and terminates
    # at the first unrecognized option.
    #############################################
    @ARGV = @$args;
    $Getopt::Long::ignorecase = 0;
    Getopt::Long::Configure( "bundling" );

    if ( !GetOptions( \%opt, qw(V|Verbose) )) {
        return( usage() );
    }
    ####################################
    # Check for "-" with no option
    ####################################
    if ( grep(/^-$/, @ARGV )) {
        return(usage( "Missing option: -" ));
    }
    ####################################
    # Check for an extra argument
    ####################################
    if ( defined( $ARGV[0] )) {
        return(usage( "Invalid Argument: $ARGV[0]" ));
    }
    ####################################
    # No operands - add command name 
    ####################################
    $request->{method} = $cmd; 
    return( \%opt );
}



##########################################################################
# Clones all the LPARs from one CEC to another (must be on same HMC) 
##########################################################################
sub clone {

    my $exp     = shift;
    my $src     = shift;
    my $dest    = shift;
    my $srcd    = shift;
    my $hwtype  = @$exp[2];
    my $server  = @$exp[3];
    my @values  = ();
    my @lpars   = ();
    my $srccec;
    my $destcec;
    my @cfgdata;
 
    #####################################
    # Always one source CEC specified 
    #####################################
    my $lparid = @$srcd[0];
    my $mtms   = @$srcd[2];
    my $type   = @$srcd[4];

    #####################################
    # Not supported on IVM 
    #####################################
    if ( $hwtype eq "ivm" ) {
        return( [[RC_ERROR,"Not supported for IVM"]] );
    }
    #####################################
    # Source must be CEC 
    #####################################
    if ( $type ne "fsp" ) {
        return( [[RC_ERROR,"Node must be an FSP"]] );
    }
    #####################################
    # Find Destination CEC 
    #####################################
    my $tab = xCAT::Table->new( "vpd" );

    #####################################
    # Error opening vpd database
    #####################################
    if ( !defined( $tab )) {
        return( [[RC_ERROR, "Error opening 'vpd' database"]] );
    }
    my ($ent) = $tab->getAttribs({node=>$dest}, qw(mtm serial));

    #####################################
    # Node not found
    #####################################
    if ( !defined( $ent )) {
        return( [[RC_ERROR,"Destination '$dest' not in 'vpd' database"]] );
    }
    #####################################
    # Attributes not found
    #####################################
    if ( !exists( $ent->{mtm} ) or !exists( $ent->{serial} )) {
        return( [[RC_ERROR,"Attributes not in 'vpd' database"]] );
    }
    my $destmtms = "$ent->{mtm}*$ent->{serial}";

    #####################################
    # Enumerate CECs
    #####################################
    my $filter = "type_model,serial_num";
    my $cecs = xCAT::PPCcli::lssyscfg( $exp, "fsps", $filter );
    my $Rc = shift(@$cecs);

    #####################################
    # Return error
    #####################################
    if ( $Rc != SUCCESS ) {
        return( [[$Rc, @$cecs[0]]] );
    }
    #####################################
    # Find source/dest CEC 
    #####################################
    foreach ( @$cecs ) {
        s/(.*),(.*)/$1*$2/;

        if ( $_ eq $mtms ) {
            $srccec = $_;
        } elsif ( $_ eq $destmtms ) {
            $destcec = $destmtms;
        }
    }
    #####################################
    # Source CEC not found
    #####################################
    if ( !defined( $srccec )) {
        return( [[RC_ERROR,"Source CEC '$src' not found"]] );
    } 
    #####################################
    # Destination CEC not found
    #####################################
    if ( !defined( $destcec )) {
        return([[RC_ERROR,"Destination CEC '$dest' not found on '$server'"]]);
    }
    #####################################
    # Get all LPARs on source CEC 
    #####################################
    my $filter = "name,lpar_id";
    my $result = xCAT::PPCcli::lssyscfg(
                                    $exp,
                                    "lpar",
                                    $srccec,
                                    $filter );
    $Rc = shift(@$result);

    #####################################
    # Return error
    #####################################
    if ( $Rc != SUCCESS  ) {
        return( [[$Rc, @$result[0]]] );
    }
    #####################################
    # Get profile for each LPAR
    #####################################
    foreach ( @$result ) {
        my ($name,$id) = split /,/;

        #################################
        # Get source LPAR profile
        #################################
        my $prof = xCAT::PPCcli::lssyscfg(
                              $exp,
                              "prof",
                              $srccec,
                              $id );

        $Rc = shift(@$prof); 

        #################################
        # Return error
        #################################
        if ( $Rc != SUCCESS ) {
            return( [[$Rc, @$prof[0]]] );
        }
        #################################
        # Save LPAR profile 
        #################################
        push @cfgdata, @$prof[0];
    }
    #####################################
    # Modify read back profile
    #####################################
    foreach my $cfg ( @cfgdata ) {
        $cfg =~ s/^name=([^,]+|$)/profile_name=$1/;
        $cfg =~ s/lpar_name=/name=/;
        $cfg = strip_profile( $cfg, $hwtype);
        my $name = $1;

        $cfg =~ /lpar_id=([^,]+)/;
        $lparid = $1;

        #################################
        # Create new LPAR  
        #################################
        my @temp = @$srcd;
        $temp[0] = $lparid;
        $temp[2] = $destcec;

        my $result = xCAT::PPCcli::mksyscfg( $exp, \@temp, $cfg ); 
        $Rc = shift(@$result);

        #################################
        # Success - add LPAR to database 
        #################################
        if ( $Rc == SUCCESS ) {
            my $err = xCATdB( "mkvm", $srcd, $lparid, $name, $hwtype );
            if ( defined( $err )) {
                push @values, [$err, RC_ERROR]; 
            } 
            next;
        }
        #################################
        # Error - Save error 
        #################################
        push @values, [@$result[0], $Rc]; 
    }
    if ( !scalar(@values) ) {
        return( [[SUCCESS,"Success"]]);
    } 
    return( \@values );
}


##########################################################################
# Removes logical partitions 
##########################################################################
sub remove {
   
    my $request = shift;
    my $hash    = shift;
    my $exp     = shift;
    my @lpars   = ();
    my @values  = ();

    while (my ($mtms,$h) = each(%$hash) ) {
        while (my ($lpar,$d) = each(%$h) ) {
            my $lparid = @$d[0];
            my $mtms   = @$d[2];
            my $type   = @$d[4];

            ####################################
            # Must be CEC or LPAR
            ####################################
            if ( $type !~ /^(lpar|fsp)$/ ) {
                push @values, [$lpar, "Node must be LPAR or CEC", RC_ERROR];
                next;
            } 
            ####################################
            # This is a single LPAR
            ####################################
            if ( $type eq "lpar" ) {
                $lpars[0] = "$lpar,$lparid";
            }
            ####################################
            # This is a CEC - remove all LPARs 
            ####################################
            else {
                my $filter = "name,lpar_id";
                my $result = xCAT::PPCcli::lssyscfg( 
                                             $exp,
                                             "lpar",
                                             $mtms,
                                             $filter );
                my $Rc = shift(@$result);

                ################################
                # Expect error
                ################################
                if ( $Rc != SUCCESS  ) {
                    push @values, [$lpar, @$result[0], $Rc];
                    next;
                }
                ################################
                # Success - save LPARs 
                ################################
                foreach ( @$result ) {
                    push @lpars, $_; 
                }
            }
            ####################################
            # Remove the LPARs
            ####################################
            foreach ( @lpars ) {
                my ($name,$id) = split /,/;
                my $mtms = @$d[2];

                ################################  
                # id profile mtms hcp type frame
                ################################  
                my @d = ( $id,0,$mtms,0,"lpar",0 );

                ################################
                # Send remove command 
                ################################
                my $result = xCAT::PPCcli::rmsyscfg( $exp, \@d );
                my $Rc = shift(@$result);

                ################################
                # Remove LPAR from database 
                ################################
                if ( $Rc == SUCCESS ) {
                    my $err = xCATdB( "rmvm", $name );
                    if ( defined( $err )) {
                        push @values, [$lpar,$err,RC_ERROR];
                        next;
                    }
                }
                push @values, [$lpar,@$result[0],$Rc];
            }
        }
    }
    return( \@values ); 
}



##########################################################################
# Changes the configuration of an existing partition 
##########################################################################
sub modify {

    my $request = shift;
    my $hash    = shift;
    my $exp     = shift;
    my $hwtype  = @$exp[2];
    my $name    = @{$request->{node}}[0];
    my $cfgdata = $request->{stdin}; 
    my @values;

    #######################################
    # Remove "node: " in case the
    # configuration file was created as
    # the result of an "lsvm" command.
    #  "lpar9: name=lpar9, lpar_name=..." 
    #######################################
    $cfgdata =~ s/^[\w]+: //;

    if ( $cfgdata !~ /^name=/ ) {
        my $text = "Invalid file format: must begin with 'name='";
        return( [[$name,$text,RC_ERROR]] );
    }

    #######################################
    # Send change profile command
    #######################################
    while (my ($cec,$h) = each(%$hash) ) {
        while (my ($lpar,$d) = each(%$h) ) {

            ###############################
            # Change configuration
            ###############################
            my $cfg = strip_profile( $cfgdata, $hwtype );
            
            ###############################
            # Additional changes 
            ###############################
            $cfg =~ s/,*lpar_env=[^,]+|$//;
            
            if ( $hwtype eq "hmc" ) {
                $cfg =~ s/,*all_resources=[^,]+|$//;
                $cfg =~ s/,*lpar_id=[^,]+|$//;          
            }
            my $result = xCAT::PPCcli::chsyscfg( $exp, $d, $cfg );
            my $Rc = shift(@$result);

            push @values, [$lpar,@$result[0],$Rc];
        }
    }
    return( \@values );
}


##########################################################################
# Lists logical partitions
##########################################################################
sub list {

    my $request = shift;
    my $hash    = shift;
    my $exp     = shift;
    my @values  = ();
    my @lpars   = ();
    my $result;

    while (my ($mtms,$h) = each(%$hash) ) {
        while (my ($lpar,$d) = each(%$h) ) {
            my $lparid = @$d[0];
            my $mtms   = @$d[2];
            my $type   = @$d[4];
            my $pprofile;

            ####################################
            # Must be CEC or LPAR
            ####################################
            if ( $type !~ /^(lpar|fsp)$/ ) {
                push @values, [$lpar,"Node must be LPAR or CEC",RC_ERROR];
                next;
            }
            ####################################
            # This is a single LPAR
            ####################################
            if ( $type eq "lpar" ) {
                $lpars[0] = "$lpar,$lparid";
            }
            ####################################
            # This is a CEC
            ####################################
            else {
                my $filter = "name,lpar_id";
                my $result = xCAT::PPCcli::lssyscfg(
                                             $exp,
                                             "lpar",
                                             $mtms,
                                             $filter );
                my $Rc = shift(@$result);

                ################################
                # Expect error
                ################################
                if ( $Rc != SUCCESS  ) {
                    push @values, [$lpar, @$result[0], $Rc];
                    next;
                }
                ################################
                # Success - save LPARs
                ################################
                foreach ( @$result ) {
                    push @lpars, $_;
                }
            }
            ####################################
            # Get LPAR profile 
            ####################################
            foreach ( @lpars ) {
                my ($name,$id) = split /,/;
            
                #################################
                # Get source LPAR profile
                #################################
                my $prof = xCAT::PPCcli::lssyscfg(
                                      $exp,
                                      "prof",
                                      $mtms,
                                      $id );
                my $Rc = shift(@$prof);

                #################################
                # Return error
                #################################
                if ( $Rc != SUCCESS ) {
                    push @values, [$lpar, @$prof[0], $Rc];
                    next;
                }
                #################################
                # List LPAR profile
                #################################
                $pprofile .= "@$prof[0]\n\n";
            }                
            push @values, [$lpar, $pprofile, SUCCESS];
        }
    }
    return( \@values );
}




##########################################################################
# Creates/changes logical partitions 
##########################################################################
sub create {

    my $request = shift;
    my $hash    = shift;
    my $exp     = shift;
    my $hwtype  = @$exp[2];
    my $opt     = $request->{opt};
    my @values  = ();
    my $result;
    my $lpar;
    my $d;
    my $lparid;
    my $mtms;
    my $type;

    #####################################
    # Get source node information
    #####################################
    while ( my ($cec,$h) = each(%$hash) ) {
        while ( my ($name,$data) = each(%$h) ) {
            $d      = $data;
            $lparid = @$d[0];
            $mtms   = @$d[2];
            $type   = @$d[4];
            $lpar   = $name;
        }
    }
    #####################################
    # Must be CEC or LPAR 
    #####################################
    if ( $type !~ /^(lpar|fsp)$/ ) {
        return( [[$lpar,"Node must be LPAR or CEC",RC_ERROR]] );
    }
    #####################################
    # Clone all the LPARs on CEC 
    #####################################
    if ( exists( $opt->{c} )) {
        my $result = clone( $exp, $lpar, $opt->{c}, $d );
        foreach ( @$result ) { 
            my $Rc = shift(@$_);
            push @values, [$opt->{c}, @$_[0], $Rc];
        }
        return( \@values ); 
    }
    #####################################
    # Get source LPAR profile  
    #####################################
    my $prof = xCAT::PPCcli::lssyscfg(
                              $exp,
                              "prof",
                              $mtms,   
                              $lparid ); 
    my $Rc = shift(@$prof);

    #####################################
    # Return error
    #####################################
    if ( $Rc != SUCCESS ) {
        return( [[$lpar, @$prof[0], $Rc]] );
    } 
    #####################################
    # Get command-line options 
    #####################################
    my $id   = $opt->{i};
    my $cfgdata = strip_profile( @$prof[0], $hwtype );

    foreach my $name ( @{$opt->{n}} ) {
        #################################
        # Modify read-back profile. 
        # See HMC or IVM mksyscfg man  
        # page for valid attributes.
        #
        #################################
        if ( $hwtype eq "hmc" ) {
            $cfgdata =~ s/^name=[^,]+|$/profile_name=$name/;
            $cfgdata =~ s/lpar_name=[^,]+|$/name=$name/;
            $cfgdata =~ s/lpar_id=[^,]+|$/lpar_id=$id/;
        }
        elsif ( $hwtype eq "ivm" ) {
            $cfgdata =~ s/^name=[^,]+|$/name=$name/;
            $cfgdata =~ s/lpar_id=[^,]+|$/lpar_id=$id/;
        }
        #################################
        # Create new LPAR  
        #################################
        $result = xCAT::PPCcli::mksyscfg( $exp, $d, $cfgdata ); 
        $Rc = shift(@$result);

        #################################
        # Add new LPAR to database 
        #################################
        if ( $Rc == SUCCESS ) {
            my $err = xCATdB( "mkvm", $name, $id, $d, $hwtype, $lpar );
            if ( defined( $err )) {
                push @values, [$name,$err,RC_ERROR];
                $id++;
                next;
            }
        }
        push @values, [$name,@$result[0],$Rc];
        $id++;
    }
    return( \@values );
}


##########################################################################
# Strips attributes from profile not valid for creation 
##########################################################################
sub strip_profile {

    my $cfgdata = shift;
    my $hwtype  = shift;

    #####################################
    # Modify read-back profile. See
    # HMC mksyscfg man page for valid
    # attributes.
    #####################################
    if ( $hwtype eq "hmc" ) {
        $cfgdata =~ s/,*\"virtual_serial_adapters=[^\"]+\"//;
        $cfgdata =~ s/,*electronic_err_reporting=[^,]+|$//;
        $cfgdata =~ s/,*shared_proc_pool_id=[^,]+|$//;
        $cfgdata =~ s/\"/\\"/g;
        $cfgdata =~ s/\n//g;
        return( $cfgdata );
    }
    #####################################
    # Modify read-back profile. See
    # IVM mksyscfg man page for valid
    # attributes.
    #####################################
    $cfgdata =~ s/,*lpar_name=[^,]+|$//;
    $cfgdata =~ s/os_type=/lpar_env=/;
    $cfgdata =~ s/,*all_resources=[^,]+|$//;
    $cfgdata =~ s/,*\"virtual_serial_adapters=[^\"]+\"//;
    $cfgdata =~ s/,*lpar_io_pool_ids=[^,]+|$//;
    $cfgdata =~ s/,*virtual_scsi_adapters=[^,]+|$//;
    $cfgdata =~ s/,*conn_monitoring=[^,]+|$//;
    $cfgdata =~ s/,*power_ctrl_lpar_ids=[^,]+|$//;
    $cfgdata =~ s/\"/\\"/g;
    return( $cfgdata );
}


##########################################################################
# Adds/removes LPARs from the xCAT database
##########################################################################
sub xCATdB {

    my $cmd     = shift;
    my $name    = shift;
    my $lparid  = shift;
    my $d       = shift;
    my $hwtype  = shift;
    my $lpar    = shift;

    #######################################
    # Remove entry 
    #######################################
    if ( $cmd eq "rmvm" ) {
        return( xCAT::PPCdb::rm_ppc( $name )); 
    }
    #######################################
    # Add entry 
    #######################################
    else {
        my ($model,$serial) = split /\*/,@$d[2]; 
        my $pprofile = $name;
        my $server   = @$d[3]; 
        my $fsp      = @$d[2];

        ###################################
        # Find FSP name in ppc database
        ###################################
        my $tab = xCAT::Table->new( "ppc" );

        ###################################
        # Error opening ppc database
        ###################################
        if ( !defined( $tab )) {
            return( "Error opening 'ppc' database" );
        }
        my ($ent) = $tab->getAttribs({node=>$lpar}, "parent" );

        ###################################
        # Node not found 
        ###################################
        if ( !defined( $ent )) { 
            return( "'$lpar' not found in 'ppc' database" );
        }
        ###################################
        # Attributes not found 
        ###################################
        if ( !exists( $ent->{parent} )) {
            return( "'parent' attribute not found in 'ppc' database" );
        }
        my $values = join( ",",
                "lpar",
                $name,
                $lparid,
                $model,
                $serial,
                $server,
                $pprofile,
                $ent->{parent} ); 
        
        return( xCAT::PPCdb::add_ppc( $hwtype, [$values] )); 
    }
    return undef;
}



##########################################################################
# Creates logical partitions 
##########################################################################
sub mkvm {
    return( create(@_) );
}

##########################################################################
# Change logical partition 
##########################################################################
sub chvm {
    return( modify(@_) );    
}


##########################################################################
# Removes logical partitions 
##########################################################################
sub rmvm  {
    return( remove(@_) );
}

##########################################################################
# Lists logical partition profile
##########################################################################
sub lsvm {
    return( list(@_) );
}



1;






