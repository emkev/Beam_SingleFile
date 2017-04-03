
/* 2016.12.08 , 12.09 , 12.16 , 12.18
   2016.12.30 , 12.31
   2017.01.02 , 01.03 , 01.05
   2017.01.07 , 01.08 , 01.10 , 01.11 , 01.12
*/

Fighter fighter ;                   // attacking-ship

ArrayList<Object> objects ;         // object-ship
ArrayList<BeamingOt> bos ;          // Beaming-ray
ArrayList<BangOt> bns ;             // Bang-Fire

ArrayList<PVector> bangCenters ;    // Bang-Fire-Center-Point
ArrayList<PVector> bangStarList ;   // Angle-Stars of a Bang-Fire

ArrayList<BigBomb> bigBombList ;    // Storing of Big BOMB
ArrayList <PVector> bombWaveList ;  // Wave-Display of Big BOMB 

ArrayList<ObjParents> ParentsList ; // List of Reproduction-Parents of object-ships 


float BeamingOtSpeed ;    // speed of a missile 

float ObjectsNum ;        // object-ship numbers
int ObjSize ;             // object-ship size
boolean ReproduceMode ;   // whether enable to reproduce children  
int ObjTopNum ;           // Top numbers of object-ships
float MutationRate ;      // mutation rate of Reproduction of object-ships

float BigBombSpeed ;      // speed of Big Bomb
float BigBombBangRadius ; // Radius of BOMB Bang

PVector FighterSpeed ;    // speed of the Fighter

boolean MouseCutMode ;    // Whether enable to Cut object-ships with Mouse


void setup() {
  
  size(1200 , 600);

  BeamingOtSpeed = 6 ;
  
  ObjectsNum = 10 ;
  ObjSize = 32 ;
  ReproduceMode = false ;
  ObjTopNum = 100 ;
  MutationRate = 0.1 ;
  
  BigBombSpeed = 3 ;
  BigBombBangRadius = 300 ;
  
  FighterSpeed = new PVector(2 , 2) ;
  
  MouseCutMode = false ;
  
  fighter = new Fighter( new PVector(width/2 , height/2) , 
                         FighterSpeed , 
                         8 , 
                         200 
                       );
  
  objects = new ArrayList<Object>() ;
  for(int i = 0 ; i < ObjectsNum ; i++) {
    objects.add( new Object( new DNA() , ObjSize ) );
  }
  
  bos = new ArrayList<BeamingOt>() ;
  bns = new ArrayList<BangOt>() ;
  
  bangCenters = new ArrayList<PVector>() ;
  bangStarList = new ArrayList<PVector>() ;
  bigBombList = new ArrayList<BigBomb>() ;
  bombWaveList = new ArrayList<PVector>() ;
  
  ParentsList = new ArrayList<ObjParents>() ;
  
  bangStarListProcessFor12() ;

}


void draw() {
    
  background(200);
  
  fighter.run();


  /*  Each object-ship ... , start  */
  for(int i = objects.size()-1 ; i >= 0 ; i--) {
    
    Object oc = objects.get(i);
    PVector sum = new PVector(0 , 0);
    int count = 0 ;

    /* when object-ships meet each other . Encounting each other start  */
    for(int r = objects.size()-1 ; r >= 0 ; r--) {
    
      Object ocm_r = objects.get(r);
      
      float dist_qr = PVector.dist( oc.location , ocm_r.location );
      
      if( dist_qr > 0 && dist_qr <= (oc.size/2 + ocm_r.size/2) ) {

        PVector diff = PVector.sub( oc.location , ocm_r.location ) ;      
        diff.normalize();
        sum.add( diff ) ;  
        count++ ;
        
        /*  2010.01.10 , 01.11 . Reproduction of object-ships .
            When 
            Enable to Reproduction Mode 
            And Object-ships number is less than the Top ,
            Can produce children .
         */
        if( ReproduceMode == true && objects.size() < ObjTopNum ) {
          ObjParents ops = new ObjParents( oc , ocm_r ) ;
          ParentsList.add( ops ) ;
        }
                
      } /*  if( dist_qr > 0 && dist_qr <= 16 )  */
    } /*  for(int r = 0 ; r < objects.size() ; r++)  */

    if( count > 0 ) {
      sum.div( count ) ;
      sum.normalize();
      sum.mult( 0.9 ) ;
      
      PVector steer = PVector.sub( sum , oc.velocity ) ;
      oc.applyForce( steer ) ;
    }
    /* Encounting each other end */

    
    /* 2017.01.11 , Mouse make objects BANG ! */
    if( MouseCutMode == true ) {
      PVector mouseLo = new PVector( mouseX , mouseY ) ;
      float distMouObj = PVector.dist( oc.location , mouseLo ) ;
      if( distMouObj >= 0.0 && distMouObj <= (ObjSize/2)*2 ) {
        oc.isBang = true ;
      }
    } 

    
    // What if current object-ship meet Beaming-rays
    /* current object-ship encounts beams , start . */
    for(int k = bos.size()-1 ; k >= 0 ; k--) {
      
      BeamingOt bo = bos.get(k) ;

      // judge that whether hitting .
      float dist = PVector.dist( oc.location , bo.location ) ;

      /* beaming-ray has hitted a object-ship , remove the beaming point .
         And being ready to remove the object-ship .
      */
      if( dist >= 0.0 && dist <= (ObjSize/2 + 7.0) ) {
        bos.remove(k);
        oc.isBang = true ;
      }            
    } /*  for(int k = bos.size()-1 ; k >= 0 ; k--)  */
    /* current object-ship encounts beams , end . */

    
    // if a object-ship has been hitted ... , OR run normally .
    if( objects.get(i).isBang == true ) {
      // store the object-ship (has been hitted) location for the central point of Bang .
      bangCenters.add( objects.get(i).location );
      objects.remove(i);
    }
    else {
      
      /* 2017.01.07 , add Gene-Vector as forces to each Object-ship . */
      oc.applyForce( oc.dna.genes[oc.geneCount] ) ;
      if( oc.geneCount >= oc.dna.geneSum - 1 ) {
        oc.geneCount = 0 ;
      }
      else {
        oc.geneCount++ ;
      }
      
      oc.run() ;
    }
    
  } /*  for(int i = objects.size()-1 ; i >= 0 ; i--)  */
  /*  Each object-ship ... , end  */


  /* 2017.01.02 , The Big BOMB ! */
  for(int g = bigBombList.size()-1 ; g >= 0 ; g--) {

    BigBomb bomb = bigBombList.get(g) ;
    bomb.run();
    PVector bbLoc = bomb.location.get() ;
    
    if( bomb.setTimeSpan <= 0 ) {
      /* Object-Ships in ALL RANGE of BOMB , ALL BANG !!! */
      for(int s = objects.size()-1 ; s >= 0 ; s--) {
    
        Object orb = objects.get(s);
    
        // so , must be in the Bang Range
        if( orb.location.x < bomb.location.x + BigBombBangRadius 
         && orb.location.x > bomb.location.x - BigBombBangRadius
         && orb.location.y < bomb.location.y + BigBombBangRadius 
         && orb.location.y > bomb.location.y - BigBombBangRadius )
        {
          bangCenters.add( objects.get(s).location );
          objects.remove(s);
        }
    
      } /*  for(int s = objects.size()-1 ; s >= 0 ; s--)  */
      
      bigBombList.remove(g);
      
      // 2017.01.03 , BANG WAVE !
      for(int t = 0 ; t < 20 ; t++) {
        bombWaveList.add(bbLoc);
      }
      
    } /*  if( bomb.setTimeSpan <= 0 )  */
  } /*  for(int g = bigBombList.size()-1 ; g >= 0 ; g--)  */
  

  // 2017.01.03 , Play a BOMB Bang Wave each frame until none .
  if( bombWaveList.size() > 0 ) {
    int waveCount = bombWaveList.size() ;
    PVector waveLoc = bombWaveList.get(waveCount-1) ;
    fill(200);
    stroke(0);
    ellipse( waveLoc.x , waveLoc.y , 30*(20 - waveCount +1) , 30*(20 - waveCount +1) );
    // Delete one after displaying a circle wave .
    bombWaveList.remove( waveCount-1 );
  }  
  

  // beaming-rays process ...
  for(int j = bos.size()-1 ; j >= 0 ; j--) {
    bos.get(j).run();
    // if beaming-ray-point times out , then it disappears 
    if( bos.get(j).lifeSpan < 0 ) {
      bos.remove(j);
    }
  }
  
  
  /* the Bang central points process ...
     store many bang-fire (from the central point of a Bang) for each Bang .
   */
  for(int m = bangCenters.size()-1 ; m >= 0 ; m--) {
    PVector bcenter = bangCenters.get(m) ;
    
    for(int n = 0 ; n < bangStarList.size() ; n++) {
      BangOt bangOt = new BangOt( bcenter , 
                                  bangStarList.get(n).get() , 
                                  ObjSize/4 , 
                                  ObjSize*2.5 ) ;
      
      bns.add(bangOt);
    }
    
    // After storing Bang-Fire , remove all Bang-Center-Point data .
    // It is necessary .
    bangCenters.remove(m);
  }
  
  
  // Bang-Fire display
  for(int p = bns.size()-1 ; p >= 0 ; p--) {
    
    BangOt bangOt = bns.get(p) ;
    
    if(bangOt.lifeSpan < 0) { 
      bns.remove(p);
    }
    
    bangOt.run();
    
  }


  /*  2010.01.10 , 01.11 , object-ship-Children Reproduction  */
  for(int w = ParentsList.size()-1 ; w >= 0 ; w--) {
    
    ObjParents objPt = ParentsList.get(w) ;
    Object obj_child = objPt.Reproduce( MutationRate , ObjSize ) ;
    objects.add( obj_child ) ;
    
    ParentsList.remove(w);
  }

}

// press mouse to fire ! fire ! fire !
void mousePressed() {
  
  PVector mouseLoc = new PVector( mouseX , mouseY ) ; 
  PVector bm = PVector.sub( mouseLoc , fighter.location ) ;
  bm.normalize();
  bm.mult( BeamingOtSpeed );
  
  // Fighter Fires !  :)
  BeamingOt bo = new BeamingOt( fighter.location , bm ) ;
  bos.add(bo);
}

void keyPressed() {

  // press key "o" to add objects-ships
  if( key == 'o' || key == 'O') {
    for(int i = 0 ; i < ObjectsNum ; i++) {
      objects.add( new Object( new DNA() , ObjSize ) );
    }
  }
  else if( key == CODED && keyCode == LEFT ) {
    fighter.turnLeft();
  }
  else if( key == CODED && keyCode == RIGHT ) {
    fighter.turnRight();
  }
  else if( key == CODED && keyCode == UP ) {
    fighter.forwardRun();
  }
  else if( key == CODED && keyCode == DOWN ) {
    fighter.reverseRun();
  }  
  else if( key == 'c' || key == 'C' ) {
    FireCircle();
  }    
  else if( key == 'b' || key == 'B' ) {
    LetsBigBomb();
  }
  else if( key == 'm' || key == 'M' ) {
    MouseCutMode = (!MouseCutMode) ;
  }
  else if( key == 'r' || key == 'R' ) {
    ReproduceMode = (!ReproduceMode) ;
  }
  else {
  }
}


void bangStarListProcessFor8() {
  
  float starAngle ; // the circling-angle of a Bang-Fire
  float starLen ;
  
  starAngle = PI/4 ;
  starLen = 1.0 ;
  
  PVector BangStar1  = new PVector(0 , -1) ;    
  PVector BangStar2  = new PVector(  ( starLen * sin(starAngle) ) ,
                                    -( starLen * cos(starAngle) )
                                   );

  PVector BangStar3  = new PVector(1 , 0) ;    
  PVector BangStar4  = new PVector(  ( starLen * cos(starAngle) ) ,
                                     ( starLen * sin(starAngle) )
                                   );

  PVector BangStar5  = new PVector(0 , 1) ;    
  PVector BangStar6  = new PVector( -( starLen * sin(starAngle) ) ,
                                     ( starLen * cos(starAngle) )
                                   );

  PVector BangStar7  = new PVector(-1 , 0) ;    
  PVector BangStar8  = new PVector( -( starLen * cos(starAngle) ) ,
                                    -( starLen * sin(starAngle) )
                                   );
                                   
  bangStarList.add(BangStar1);
  bangStarList.add(BangStar2);
  bangStarList.add(BangStar3);
  bangStarList.add(BangStar4);
  
  bangStarList.add(BangStar5);
  bangStarList.add(BangStar6);
  bangStarList.add(BangStar7);
  bangStarList.add(BangStar8);

}

void bangStarListProcessFor12() {
  
  float starAngle ; // the circling-angle of a Bang-Fire
  float starLen ;
  
  starAngle = PI/6 ;
  starLen = 1.0 ;
  
  PVector BangStar1  = new PVector(0 , -1) ;    
  PVector BangStar2  = new PVector(  ( starLen * sin(starAngle) ) ,
                                    -( starLen * cos(starAngle) )
                                   );
  PVector BangStar12 = new PVector( -( starLen * sin(starAngle) ) ,
                                    -( starLen * cos(starAngle) )    
                                   );
  
  PVector BangStar4  = new PVector(1 , 0) ;
  PVector BangStar3  = new PVector(  ( starLen * cos(starAngle) ) ,
                                    -( starLen * sin(starAngle) ) 
                                   ) ;
  PVector BangStar5  = new PVector(  ( starLen * cos(starAngle) ) ,
                                     ( starLen * sin(starAngle) ) 
                                   ) ;

  PVector BangStar7  = new PVector(0 , 1) ;
  PVector BangStar6  = new PVector(  ( starLen * sin(starAngle) ) ,
                                     ( starLen * cos(starAngle) ) 
                                   ) ;
  PVector BangStar8  = new PVector( -( starLen * sin(starAngle) ) ,
                                     ( starLen * cos(starAngle) ) 
                                   ) ;

  PVector BangStar10 = new PVector(-1 , 0) ;
  PVector BangStar11 = new PVector( -( starLen * cos(starAngle) ) ,
                                    -( starLen * sin(starAngle) ) 
                                   ) ;
  PVector BangStar9  = new PVector( -( starLen * cos(starAngle) ) ,
                                     ( starLen * sin(starAngle) ) 
                                   ) ;


  bangStarList.add(BangStar1);
  bangStarList.add(BangStar2);
  bangStarList.add(BangStar3);
  bangStarList.add(BangStar4);
  bangStarList.add(BangStar5);
  bangStarList.add(BangStar6);

  bangStarList.add(BangStar7);
  bangStarList.add(BangStar8);
  bangStarList.add(BangStar9);
  bangStarList.add(BangStar10);
  bangStarList.add(BangStar11);
  bangStarList.add(BangStar12);

}

// 2016.12.18 , fire circle-beaming . Bang ! Bang ! Bang !
void FireCircle() {
    
  for(int i = 0 ; i < bangStarList.size() ; i++) {
    
    PVector bmv = bangStarList.get(i).get() ;
    /* NOTE !!!
       PVector bmv = bangStarList.get(i) ;
       Means that : 
       "bmv" IS the "bangStarList" factor .
       Operating "bmv" IS operating the "bangStarList" factor absolutely .
    */
    bmv.normalize();
    bmv.mult( BeamingOtSpeed );
    
    BeamingOt bmot = new BeamingOt( fighter.location , bmv ) ;
    bos.add(bmot);

  }
}


/* 2017.01.02 am 02:43 */
void LetsBigBomb() {

  // Only one BOMB in a time .
  if( bigBombList.size() == 0 ) {
      
    PVector mouseLocation = new PVector( mouseX , mouseY ) ; 
    PVector lbb = PVector.sub( mouseLocation , fighter.location ) ;
    lbb.normalize();
    lbb.mult( BigBombSpeed );
  
    BigBomb bb = new BigBomb( fighter.location , lbb ) ;
    bigBombList.add(bb);
  }
  
}

/*** BangOt ****/

/* 2016.12.08 ,
   2016.12.09
   2016.12.16
   2017.01.11
*/

class BangOt extends Particle {

  float lifeSpan ;
  
  BangOt( PVector l , PVector v , int s , float lSpan ) {
    super( l , v );
    
    // normal is 40.0
    lifeSpan = lSpan ;

    // normal is 6
    size = s ;
    bodyColor1 = 180.0 ;
    bodyColor2 = 50.0 ;
    bodyColor3 = 50.0 ;
    
  }
  
  void run() {
    super.run();
    lifeSpan-- ;
  }
  
}

/**** BeamingOt *****/


/* 2016.12.08 ,
   2016.12.16
*/

class BeamingOt extends Particle {

  float lifeSpan ;
  float r ;
  
  BeamingOt( PVector l , PVector v ) {
    super( l , v );
    
    lifeSpan = 255 ;
    r = 2 ;
  }
  
  void run() {
    super.run();
    lifeSpan -= 2 ;
  }
  
  void display() {

    //ellipse( location.x , location.y , 12 , 12 );    
    float theta = velocity.heading2D() + PI/2 ;
    fill(200);
    stroke(0);
    
    pushMatrix();
    translate( location.x , location.y );
    rotate( theta );
    
    /* missile body */
    beginShape();
    vertex(  0 , -(r*9) );
    vertex( -r , -(r*4) );
    vertex( -r ,     0  );
    vertex(  r ,     0  );
    vertex(  r , -(r*4) );    
    endShape( CLOSE );
    
    /* left and right bottom wing */
    /*
    beginShape();    
    vertex( -r , -(r*2) );
    vertex( -(r*2) , 0 );
    vertex( -r ,     0  );
    endShape( CLOSE );

    beginShape();    
    vertex(  r , -(r*2) );
    vertex( r*2 , 0 );
    vertex( r ,     0  );
    endShape( CLOSE );
    */
    
    /* left and right front wing */
    /*
    beginShape();    
    vertex( -r     , -(r*4) );
    vertex( -(r*3/2) , -(r*3) );
    vertex( -(r*3/2) , -(r) );
    vertex( -r ,     -(r) );
    endShape( CLOSE );
    
    beginShape();    
    vertex( r   , -(r*4) );
    vertex( r*3/2 , -(r*3) );
    vertex( r*3/2 , -(r)   );
    vertex( r   , -(r) );
    endShape( CLOSE );
    */    

    /* left and right long wing */
    beginShape();    
    vertex( -r     , -(r*3) );
    vertex( -(r*2) , -(r*2) );
    vertex( -(r*2) , 0 );
    vertex( -r ,     0 );
    endShape( CLOSE );
    
    beginShape();    
    vertex( r   , -(r*3) );
    vertex( r*2 , -(r*2) );
    vertex( r*2 , 0   );
    vertex( r   , 0 );
    endShape( CLOSE );
    
    popMatrix();
  }
  
}

/**** BigBomb ****/


/* 2017.01.02 am 02:46 
   2017.01.11 
*/

class BigBomb extends Particle {
 
  float setTimeSpan ;
  
  BigBomb( PVector l , PVector v ) {
    super( l , v ) ;
    setTimeSpan = 80 ;

    size = 32 ;
    bodyColor1 = 50.0 ;
    bodyColor2 = 50.0 ;
    bodyColor3 = 50.0 ;
    
  }
  
  void run() {
    super.run();
    setTimeSpan -= 2 ;
  }
  
  void display() {

    fill( bodyColor1 , bodyColor2 , bodyColor3 ) ;

    ellipse( location.x , location.y , size , size );

    pushMatrix();
    translate( location.x , location.y ) ;
    rotate( PI/4 ) ;
    rect( -8 , -18 , 16 , 12 ) ;
    rect( -1 , -30 , 2  , 12 ) ;
    popMatrix();
  }
  
}


/*** DNA ***/


/* 2017.01.05 am 01:19 
   DNA class as the force about the object-ship flying . 
   2017.01.07
   2017.01.10 , correct Mutation Rate function .
*/

class DNA {
 
  PVector[] genes ;
  int geneSum ;
  float maxStrength ;
  
  DNA() {
    geneSum = 50 ;
    maxStrength = 0.25 ;
    genes = new PVector[geneSum] ;
    
    for(int i = 0 ; i < geneSum ; i++) {
      PVector randomVec = new PVector( random(-100 , 100) , random(-100 , 100) ) ;
      randomVec.normalize();
      randomVec.mult( maxStrength );
      genes[i] = randomVec ;
    }
    
  }

  DNA( PVector[] newGenes ) {
    geneSum = newGenes.length ;
    maxStrength = 0.25 ;
    genes = newGenes ;
  }
  
  
  DNA CrossOver( DNA partnerDNA ) {
    
    PVector[] childGenes = new PVector[geneSum] ;
    
    int midPoint = (int)random( 0 , geneSum-1 ) ;
    
    for(int i = 0 ; i <= midPoint ; i++) {
      childGenes[i] = genes[i] ;
    }
    
    for(int j = midPoint+1 ; j < geneSum ; j++) {
      childGenes[j] = partnerDNA.genes[j] ;
    }
    
    DNA childDNA = new DNA( childGenes ) ;
    
    return childDNA ;
  }
  
  /* Mutation activity is about Whether mutate for each GENE . */
  void Mutate( float mutationRate ) {
    
    for(int k = 0 ; k < geneSum ; k++) {
    
      if( random(1) < mutationRate ) {
      
        PVector newPoint = new PVector( random(-100 , 100) , random(-100 , 100) ) ;
        newPoint.normalize();
        newPoint.mult( maxStrength );
        genes[k] = newPoint ;

      }
    } /*  for(int k = 0 ; k < geneSum ; k++)  */
    
  }
 
}

/**** Fighter ****/


/* 2016.12.08 , 
   2017.01.11
*/

class Fighter extends Particle {
 
  float turnStrength ;
  float runStrength ; 
  
  Fighter(PVector l) {
    super(l);
    turnStrength = 3.0 ;
    runStrength = 1.5 ;
    
    bodyColor1 = 204.0 ;
    bodyColor2 = 102.0 ;
    bodyColor3 = 0.0 ;
    
  }
  
  Fighter(PVector l , PVector v , float s , float c) {
    super( l , v , s , c );
    turnStrength = 3.0 ;
    runStrength = 1.5 ;

    bodyColor1 = 204.0 ;
    bodyColor2 = 102.0 ;
    bodyColor3 = 0.0 ;
  }
  
  void display() {
    fill( bodyColor1 , bodyColor2 , bodyColor3 ) ;
    ellipse( location.x , location.y , 20 , 20 );
    ellipse( location.x , location.y ,  8 ,  8 );
    
    // four circles
    ellipse( location.x-8  , location.y , 2 , 2 );
    ellipse( location.x+8 , location.y ,  2 , 2 );
    ellipse( location.x , location.y-8 ,  2 , 2 );
    ellipse( location.x , location.y+8 ,  2 , 2 );
  }
  
  void turnLeft() {

    float theta , alpha ;
    float steerX , steerY ;
    
    PVector steer ;
    PVector vh ;
    
    vh = velocity.get();

    if( vh.x == 0 && vh.y == 0 ) {
      steer = new PVector( -1 , 0 ) ;
    }
    else if( vh.x == 0 && vh.y < 0 ) {  
      steer = new PVector( -1 , 0 ) ;
    }
    else if( vh.x == 0 && vh.y > 0 ) {
      steer = new PVector( 1 , 0 ) ;
    }
    else if( vh.x < 0 && vh.y == 0 ) {
      steer = new PVector( 0 , 1 ) ;
    }
    else if( vh.x > 0 && vh.y == 0 ) {
      steer = new PVector( 0 , -1 ) ;
    }
    
    else if( vh.x < 0 && vh.y < 0 ) {  
      theta = asin( -(vh.y) / vh.mag() );
      alpha = PI/2 - theta ;
      steerX = -( cos(alpha) * vh.mag() ) ;
      steerY =  ( sin(alpha) * vh.mag() ) ;
      steer = new PVector( steerX , steerY ) ;
    }
    else if( vh.x > 0 && vh.y < 0 ) {
      theta = asin( vh.x / vh.mag() );
      alpha = PI/2 - theta ;
      steerX = -( sin(alpha) * vh.mag() ) ;
      steerY = -( cos(alpha) * vh.mag() ) ;
      steer = new PVector( steerX , steerY ) ;
    }
    else if( vh.x > 0 && vh.y > 0 ) {
      theta = asin( vh.y / vh.mag() );
      alpha = PI/2 - theta ;
      steerX =  ( cos(alpha) * vh.mag() ) ;
      steerY = -( sin(alpha) * vh.mag() ) ;
      steer = new PVector( steerX , steerY ) ;
    }
    else if( vh.x < 0 && vh.y > 0 ) {
      theta = asin( -(vh.x) / vh.mag() );
      alpha = PI/2 - theta ;
      steerX = ( sin(alpha) * vh.mag() ) ;
      steerY = ( cos(alpha) * vh.mag() ) ;
      steer = new PVector( steerX , steerY ) ;
    }
    else {
      steer = new PVector( -1 , 0 ) ;
    }
    
    steer.normalize();
    // turning strength
    steer.mult(turnStrength);
    
    applyForce(steer);    
  }

  void turnRight() {
    
    float theta , alpha ;
    float steerX , steerY ;
    
    PVector steer ;
    PVector vh ;
    
    vh = velocity.get();
    
    if( vh.x == 0 && vh.y == 0 ) {
      steer = new PVector( 1 , 0 ) ;
    }
    else if( vh.x == 0 && vh.y < 0 ) {  
      steer = new PVector( 1 , 0 ) ;
    }
    else if( vh.x == 0 && vh.y > 0 ) {
      steer = new PVector( -1 , 0 ) ;
    }
    else if( vh.x < 0 && vh.y == 0 ) {
      steer = new PVector( 0 , -1 ) ;
    }
    else if( vh.x > 0 && vh.y == 0 ) {
      steer = new PVector( 0 , 1 ) ;
    }
    
    else if( vh.x < 0 && vh.y < 0 ) {  
      theta = asin( -(vh.x) / vh.mag() );
      alpha = PI/2 - theta ;
      steerX =  ( sin(alpha) * vh.mag() ) ;
      steerY = -( cos(alpha) * vh.mag() ) ;
      steer = new PVector( steerX , steerY ) ;
    }    
    else if( vh.x > 0 && vh.y < 0 ) {
      theta = asin( (-vh.y) / vh.mag() );
      alpha = PI/2 - theta ;
      steerX = sin(alpha) * vh.mag() ;
      steerY = cos(alpha) * vh.mag() ;
      steer = new PVector( steerX , steerY ) ;
    }    
    else if( vh.x > 0 && vh.y > 0 ) {
      theta = asin( vh.x / vh.mag() );
      alpha = PI/2 - theta ;
      steerX = -( sin(alpha) * vh.mag() ) ;
      steerY = cos(alpha) * vh.mag() ;
      steer = new PVector( steerX , steerY ) ;
    }
    else if( vh.x < 0 && vh.y > 0 ) {
      theta = asin( vh.y / vh.mag() );
      alpha = PI/2 - theta ;
      steerX = -( cos(alpha) * vh.mag() ) ;
      steerY = -( sin(alpha) * vh.mag() ) ;
      steer = new PVector( steerX , steerY ) ;
    }
    else {
      steer = new PVector( 1 , 0 ) ;
    }
    
    steer.normalize();
    // turning strength
    steer.mult(turnStrength);
    
    applyForce(steer);    
  }
 
  // run run run 
  void forwardRun() {
    
    PVector steer ;
    
    PVector vh = velocity.get();
    vh.normalize();
    vh.mult(runStrength);
    
    steer = vh ;
    
    applyForce(steer);
  }

  // slow slow slow  
  void reverseRun() {
    
    PVector steer ;
    PVector vh = velocity.get();

    if( vh.x == 0 && vh.y == 0 ) {
      steer = new PVector( 0 , 0 ) ;
    }
    else if( vh.x == 0 && vh.y < 0 ) {  
      steer = new PVector( 0 , -(vh.y) ) ;
    }
    else if( vh.x == 0 && vh.y > 0 ) {
      steer = new PVector( 0 , -(vh.y) ) ;
    }
    else if( vh.x < 0 && vh.y == 0 ) {
      steer = new PVector( -(vh.x) , 0 ) ;
    }
    else if( vh.x > 0 && vh.y == 0 ) {
      steer = new PVector( -(vh.x) , 0 ) ;
    }
    else {
      steer = new PVector( -(vh.x) , -(vh.y) ) ;
    }
    
    steer.normalize();
    steer.mult(runStrength);
    
    applyForce(steer);
  }
  
}

/*** ObjParents ******/


/*  2017.01.10 , 
    2017.01.11 , add Reproduce function 
*/

class ObjParents {
  
  Object Mobj ;
  Object Fobj ;
  //float MutationRate ;
  
  ObjParents( Object m , Object f ) {
    Mobj = m ;
    Fobj = f ;
  }
  
  Object Reproduce( float mur , int objSize ) {
    
    DNA childDna = Mobj.dna.CrossOver( Fobj.dna ) ;
    childDna.Mutate( mur ) ;
    Object obj = new Object( childDna , objSize ) ;
    
    return obj ;
  }
  
}


/**** Object ****/


/* 2016.12.08 
   2017.01.05 , add DNA class as run-force , and add life span .
   2017.01.07 , add applying the gene vector as force .
   2017.01.11 , using common size and displaying function of particle class .
*/

class Object extends Particle {

  DNA dna ;
  int lifeSpan ;
  boolean isBang ;
  int geneCount ;
  
  Object( DNA _dna , int s ) {
    super();
    dna = _dna ;
    isBang = false ;
    lifeSpan = 500 ;
    geneCount = 0 ;

    // normal is 16
    size = s ;
    
    bodyColor1 = 50.0 ;
    bodyColor2 = 50.0 ;
    bodyColor3 = 100.0 ;

  }
  
  void run() {
    super.run() ;
    //lifeSpan -= 1 ;
  }
    
}

/**** Particle ******/


/* 2016.12.08 
   2017.01.11 , add 'size' variable to display() .
*/

class Particle
{
  PVector location ;
  PVector velocity ;
  PVector acceleration ;
  
  float maxSpeed ;
  float size ;
  float bodyColor1 , bodyColor2 , bodyColor3 ; 
  
  Particle() {

    location = new PVector( random(width) , random(height) ) ;
    velocity = new PVector(1 , 1) ;
    acceleration = new PVector(0 , 0) ;
    
    maxSpeed = 10 ;
    size = 16 ;
    bodyColor1 = 50.0 ;
    bodyColor2 = 50.0 ;
    bodyColor3 = 50.0 ;
  }
  
  Particle( PVector l ) {
    location = l.get() ;
    velocity = new PVector(0 , 0) ;
    acceleration = new PVector(0 , 0) ;
    
    maxSpeed = 10 ;
    size = 16 ;
    bodyColor1 = 50.0 ;
    bodyColor2 = 50.0 ;
    bodyColor3 = 50.0 ;
  }

  Particle( PVector l , PVector v ) {
    location = l.get() ;
    velocity = v.get() ;
    acceleration = new PVector(0 , 0) ;
    
    maxSpeed = 10 ;
    size = 16 ;
    bodyColor1 = 50.0 ;
    bodyColor2 = 50.0 ;
    bodyColor3 = 50.0 ;
  }
  
  Particle(PVector l , PVector v , float s , float c) {
    
    location = l.get();
    velocity = v.get();
    acceleration = new PVector(0 , 0) ;
    
    maxSpeed = 10 ;
    size = s ;
    bodyColor1 = 50.0 ;
    bodyColor2 = 50.0 ;
    bodyColor3 = 50.0 ;
  }
  
  void applyForce(PVector f) {
    acceleration.add(f);
  }
  
  void run() {
    update();
    checkEdge();
    display();
  }
  
  void update() {
    
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    location.add(velocity);
    
    acceleration.mult(0);
  }
  
  void checkEdge() {
    
    if( ((location.x-size/2) < 0) || ((location.x+size/2) > width) )
      velocity.x = (-1) * velocity.x ;
     
    if( ((location.y-size/2) < 0) || ((location.y+size/2) > height) )
      velocity.y = (-1) * velocity.y ; 
  }
  
  void display() {
    fill( bodyColor1 , bodyColor2 , bodyColor3 );
    ellipse(location.x , location.y , size , size) ;
  }
  
}





