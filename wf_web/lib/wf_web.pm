package wf_web;
use Dancer ':syntax';
use strict;
use warnings;
use Cwd;
use Sys::Hostname;
use Dancer::Plugin::REST;
use Dancer::Plugin::RequireSSL;
#use Dancer::Plugin::FlashMessage;
use DBI;
use DBD::SQLite;
use Imager::QRCode;
use utf8::all;
use Data::Dumper;
use DateTime;
use DateTime::Format::DateParse;
use DateTime::Format::Duration;
#use Carp::Always;


our $VERSION = '0.1';

set serializer => 'JSON';
#require_ssl();

sub generateQRCode {

    my $string = shift;
    my $qrcode = Imager::QRCode->new(
        size            => 10,
        version         => 1,
        level           => 'M',
        casesensitive   => 1,
        lightcolor      => Imager::Color->new(255,255,255),
        darkcolor       => Imager::Color->new(0,0,0),
    );

    my $img = $qrcode->plot($string);

    return $img;

}


get '/' => sub {

    my $driver   = "SQLite";
    my $database = "db/wf_db.db";
    my $dsn = "DBI:$driver:dbname=$database";
    my $userid = "";
    my $password = "";
    my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
        or die $DBI::errstr;

    my $stmt = qq(select * from competitions);
    my $sth = $dbh->prepare( $stmt );
    my $rv = $sth->execute() or die $DBI::errstr;
    
    my $res;

    while(my @row = $sth->fetchrow_array()) {
        my $id = $row[0];
        $res->{$id}->{desc} = $row[1];
        $res->{$id}->{date} = $row[2];
        $res->{$id}->{place} = $row[3];        
    }

    template 'index', {
        'entries' => $res
    };
};

get '/register/:id' => sub {

    template 'register', {
    };

};


post '/register/:id' => sub {

    my $user = param 'username';
    my $telef = param 'telef';
    my $raceID = param 'id';
    my $qrcode = "$user::$telef::$raceID";
    my $nulls = undef;
    
    $qrcode =~ s/\s+//g;
    
    my $img = generateQRCode($qrcode);
    $img->write(file => "public/qrcodes/$qrcode.jpg");


    my $driver   = "SQLite";
    my $database = "db/wf_db.db";
    my $dsn = "DBI:$driver:dbname=$database";
    my $userid = "";
    my $password = "";
    my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
        or die $DBI::errstr;

    my $stmt = qq(insert into riders (name,tnumber,qrcode) values ("$user","$telef","$qrcode"));
    my $sth = $dbh->prepare( $stmt );
    my $rv = $sth->execute() or die $DBI::errstr;

    my $riderID = $dbh->func("last_insert_rowid");    
    
    $stmt = qq(insert into race (rider,competition,validated,check1,check2,final) values (?,?,?,?,?,?));
    $sth = $dbh->prepare ($stmt);
    $rv = $sth->execute($riderID,$raceID,undef,undef,undef,undef) or die $DBI::errstr;  

    template '/show_registration', {
        'riderID' => $riderID,
        'qrcode' => $qrcode,
    }

};


get '/show_registration/:riderID/:qrcode' => sub {

};


get '/validateRider/:qrcode' => sub {

    my $qrcode = param 'qrcode';
    my $driver = "SQLite";
    my $database = "db/wf_db.db";
    my $dsn = "DBI:$driver:dbname=$database";
    my $userid = "";
    my $password = "";
    my $dbh = DBI->connect($dsn,$userid,$password, { RaiseError => 1}) or die $DBI::errstr;

    
    $qrcode =~ m/(.*)::(.*)::(.*)/g;

    my $user = $1;
    my $telef = $2;
    my $raceID = $3;
    
    my $stmt = qq (select id,name from riders where tnumber = $telef);
    my $sth = $dbh->prepare($stmt);
    my $rv = $sth->execute() or die $DBI::errstr;
    my @row = $sth->fetchrow_array();
    my $result = $row[0];
    my $name = $row[1];

    my $timestamp = DateTime->now();

    $stmt = qq(update race set validated = "$timestamp" where rider = $result and competition = $raceID );

    $sth = $dbh->prepare($stmt);
    $rv = $sth->execute() or die $DBI::errstr;



   status_ok ( {name => $name, result => $result, user => $user, race => $3} ); 
    

};



get '/setTime/:qrcode' => sub {
   my $qrcode = param 'qrcode';
    my $driver = "SQLite";
    my $database = "db/wf_db.db";
    my $dsn = "DBI:$driver:dbname=$database";
    my $userid = "";
    my $password = "";
    my $dbh = DBI->connect($dsn,$userid,$password, { RaiseError => 1}) or die $DBI::errstr;

    
    $qrcode =~ m/(.*)::(.*)::(.*)/g;

    my $user = $1;
    my $telef = $2;
    my $raceID = $3;
    
    my $stmt = qq (select id,name from riders where tnumber = $telef);
    my $sth = $dbh->prepare($stmt);
    my $rv = $sth->execute() or die $DBI::errstr;
    my @row = $sth->fetchrow_array();
    my $result = $row[0];
    my $name = $row[1];

    my $timestamp = DateTime->now();

    $stmt = qq (select validated from race where rider = $result and competition = $raceID);
    $sth = $dbh->prepare($stmt);
    $rv = $sth->execute();
    @row = $sth->fetchrow_array();

    my $validated = $row[0];


    if ($validated) {
        $stmt = qq(update race set final = "$timestamp" where rider = $result and competition = $raceID and final is NULL and check2 is not NULL);

        $sth = $dbh->prepare($stmt);
        $rv = $sth->execute() or die $DBI::errstr;

         $stmt = qq(update race set check2 = "$timestamp" where rider = $result and competition = $raceID and check2 is NULL and check1 is not NULL);

        $sth = $dbh->prepare($stmt);
        $rv = $sth->execute() or die $DBI::errstr;

        $stmt = qq(update race set check1 = "$timestamp" where rider = $result and competition = $raceID and check1 is NULL );

        $sth = $dbh->prepare($stmt);
        $rv = $sth->execute() or die $DBI::errstr;  

       status_ok ( {name => $name, result => $result, user => $user, race => $3, validated => "true"} ); 
   }
   else {
        status_ok ( {name => $name, validated => "false" } );
   }

};


get '/results/:idRace' => sub {

    my $idRace = param 'idRace';
    my $driver = "SQLite";
    my $database = "db/wf_db.db";
    my $dsn = "DBI:$driver:dbname=$database";
    my $userid = "";
    my $password = "";
    my $dbh = DBI->connect($dsn,$userid,$password, { RaiseError => 1}) or die $DBI::errstr;
    my $stmt = qq (select * from race where competition = $idRace);
    my $sth = $dbh->prepare($stmt);
    my $rv = $sth->execute();

    my $results;

    my $row = $sth->fetchall_arrayref();

    
    foreach my $r (@{$row}) {

        my @row = @{$r};

        my $id = $row[0];
        my $idRider = $row[1];
        my $validated = DateTime::Format::DateParse->parse_datetime($row[3]);
        my $check1 = DateTime::Format::DateParse->parse_datetime($row[4]);
        my $check2 = DateTime::Format::DateParse->parse_datetime($row[5]);
        my $final = DateTime::Format::DateParse->parse_datetime($row[6]);
      
        my $stmt2 = qq (select name from riders where id = $idRider);
        my $sth2 = $dbh->prepare($stmt2);
        my $rv2 = $sth2->execute();

        my @v = $sth2->fetchrow_array();
        my $name = $v[0];

        $stmt2 = qq (select desc from competitions where id = $idRace);
        $sth2 = $dbh->prepare($stmt2);
        $rv2 = $sth2->execute();

        @v = $sth2->fetchrow_array();
        my $raceDesc = $v[0];


        
        if (defined $validated and defined $check1 
                and defined $check2 and defined $final) {

            my $t1 = $check1->subtract_datetime($validated) ;
            my $t2 = $check2->subtract_datetime($check1);
            my $t3 = $final->subtract_datetime ($check2);          

                       my $date = DateTime::Format::Duration->new (
                pattern => '%H:%M:%S'
            );
         
            $results->{$name}->{t1} = $date->format_duration($t1);
            $results->{$name}->{t2} = $date->format_duration($t2);
            $results->{$name}->{t3} = $date->format_duration($t3);
            $results->{$name}->{desc} = $raceDesc;

            my $tmp = $t1->add($t2);
            my $tmp2 = $tmp->add($t3);

            $results->{$name}->{total} = $date->format_duration($tmp2); 
        }
        else {
            $results->{$name}->{t1} = "00:00:00";
            $results->{$name}->{t2} = "00:00:00";
            $results->{$name}->{t3} = "00:00:00";
            $results->{$name}->{total} = "00:00:00";
            $results->{$name}->{desc} = $raceDesc;

        }
     }
    

    template '/results', {
        'results' => $results
    }

};

get '/syncOfflineData/:qrcode/:validated/:check1/:check2/:final' => sub {
  
    my $qrcode = param 'qrcode';
    my $validated = param 'validated';
    my $check1 = param 'check1';
    my $check2 = param 'check2';
    my $final = param 'final';

   
    my $driver = "SQLite";
    my $database = "db/wf_db.db";
    my $dsn = "DBI:$driver:dbname=$database";
    my $userid = "";
    my $password = "";
    my $dbh = DBI->connect($dsn,$userid,$password, { RaiseError => 1}) or die $DBI::errstr;

    
   print "$qrcode + $validated + $check1 + $check2 + $final"; 


   status_ok( {results => "OK"} );

};




true;
