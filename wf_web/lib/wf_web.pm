package wf_web;
use Dancer ':syntax';
use strict;
use warnings;
use Cwd;
use Sys::Hostname;
use DBI;
use DBD::SQLite;
use Imager::QRCode;

our $VERSION = '0.1';


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

    $stmt = qq(insert into race (rider,competition,validated,check1,check2,final) values ("$riderID","$raceID","NULL","NULL","NULL","NULL"));
    $sth = $dbh->prepare ($stmt);
    $rv = $sth->execute() or die $DBI::errstr;  

    template '/show_registration', {
        'riderID' => $riderID,
        'qrcode' => $qrcode,
    }

};


get '/show_registration/:riderID/:qrcode' => sub {

};


get '/validateRider/:qrcode' => sub {

    my $qrcode = param 'qrcode';

    $qrcode =~ m/(.*)::(.*)::(.*)/g;

    my $user = $1;
    my $raceID = $3; 
    
    open FILE, ">keylogger.dat";  #opens file to be written to
        
           print FILE $user;             #write it to our file
           print FILE $raceID;
       close FILE;                   #then close our file.


};


true;
