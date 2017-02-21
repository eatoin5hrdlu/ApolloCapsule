#!C:/Perl/bin/perl -w
use strict;

use OpenGL qw/ :all /;

eval 'use OpenGL::Image';
my $hasImage = !$@;
my $hasIM_635 = $hasImage && OpenGL::Image::HasEngine('Magick','6.3.5');

eval 'use OpenGL::Shader';
my $hasShader = !$@;

eval 'use Image::Magick';
my $hasIM = !$@;

use Math::Trig;
eval 'use Time::HiRes qw( gettimeofday )';
my $hasHires = !$@;
$|++;


# ----------------------
# Based on a cube demo by
# Chris Halsall (chalsall@chalsall.com) for the
# O'Reilly Network on Linux.com (oreilly.linux.com).
# May 2000.
#
# Translated from C to Perl by J-L Morel <jl_morel@bribes.org>
# ( http://www.bribes.org/perl/wopengl.html )
#
# Updated for FBO, VBO, Vertex/Fragment Program extensions
# and ImageMagick support
# by Bob "grafman" Free <grafman@graphcomp.com>
# ( http://graphcomp.com/opengl )
#

my $PROGRAM_TITLE = " "x160 . "Moon";
use constant DO_TESTS => 0;

# We can be near {EARTH,MOON} and
# either headed down to the surface
# or back toward the {MOON,EARTH}.

use constant EARTH   => 1;
use constant MOON    => 0;
use constant NEAR    => 2;
use constant FAR     => 0;

# Some global variables.
my $gState;
my $gSwitched;
my $useMipMap = 1;
my $hasFBO = 0;
my $hasVBO = 0;
my $hasFragProg = 0;
my $hasImagePointer = 0;
my $er;

# Window and texture IDs, window width and height.
my $Window_ID;
my $Window_Width = 1428;
my $Window_Height = 1024;
my $Inset_Width = 90;
my $Inset_Height = 90;
my $Save_Width;
my $Save_Height;
my $nextTex;
my $nextPhase;
my ($rcTID, $rcIDFBO);
my ($newTID, $newIDFBO);


my ($gDoTime, $gDoFunc, @gDoArgs);
my $texture;
# Texture dimanesions
my $idir = "C:/Apache2/htdocs/Museum/Aerospace/apollo/images";

my @Tex_Files = qw(
		   halfmoon.tga
		   halfearth.tga
		   m1.tga
		   e1.tga
		   sol.tga
		   e2.tga
		   m3.tga
		   e3.tga
		    );


my (@gIHeight, @gIWidth, @gMinZ, @gMaxZ, @gMaxXRot, @gMinXRot, @gMaxYRot, @gMinYRot);

my $Tex_Width = 128;
my $Tex_Height = 128;
my $Tex_Format;
my $Tex_Type;
my $Tex_Size;
my @Tex_Image;
my @Tex_Pixels;

# Our display mode settings.
my $Light_On = 0;
my $Blend_On = 0;
my $Texture_On = 1;
my $Alpha_Add = 1;
my $FBO_On = 0;
my $Inset_On = 1;
my $Fullscreen_On = 0;

my $Curr_TexMode = 0;
my @TexModesStr = qw/ GL_DECAL GL_MODULATE GL_BLEND GL_REPLACE /;
my @TexModes = ( GL_DECAL, GL_MODULATE, GL_BLEND, GL_REPLACE );
my(@TextureID_image, @TextureID_FBO);
my @FrameBufferID;
my @RenderBufferID;
my $VertexProgID;
my $FragProgID;
my $FBO_rendered = 0;
my $Shader;

# Object and scene global variables.
my $Teapot_Rot = 0.0;

# Cube position and rotation speed variables.
my $X_Rot;   # = 0.0;
my $Y_Rot;   # = 0.0;
my $X_Speed; # = 0.1;
my $Y_Speed; # = 0.1;
my $gSpeed_Increment; #  = 0.1;
my $Z_Off;   #   =-3.0;
my $saveZ;   #   =-3.0;

# Settings for our light.  Try playing with these (or add more lights).
my @Light_Ambient  = ( 0.1, 0.1, 0.1, 1.0 );
my @Light_Diffuse  = ( 1.2, 1.2, 1.2, 1.0 );
my @Light_Position = ( 2.0, 2.0, 0.0, 1.0 );

# Vertex Buffer Object data
my($VertexObjID,$NormalObjID,$ColorObjID,$TexCoordObjID,$IndexObjID);

my @verts =
(

  -3.0, -3.0, -15.3,
  -3.0,  3.0, -15.3,
  3.0,  3.0, -15.3,
  3.0, -3.0, -15.3,

  -3.0, -3.0,  15.3,
  3.0, -3.0,  15.3,
  3.0,  3.0,  15.3,
  -3.0,  3.0,  15.3,

  -40.3, -3.0, -3.0,
  -40.3, -3.0,  3.0,
  -40.3,  3.0,  3.0,
  -40.3,  3.0, -3.0,

  1.3, -3.0, -3.0,
  1.3,  3.0, -3.0,
  1.3,  3.0,  3.0,
  1.3, -3.0,  3.0,

#TOP
  -1.0,  1.3, -1.0,
  -1.0,  1.3,  1.0,
  1.0,  1.3,  1.0,
  1.0,  1.3, -1.0,

#BOTTOM

  -1.0, -1.3, -1.0,
  1.0, -1.3, -1.0,
  1.0, -1.3,  1.0,
  -1.0, -1.3,  1.0,



);
my $verts = OpenGL::Array->new_list(GL_FLOAT,@verts);

# Could calc norms on the fly
my @norms =
(
  0.0, -1.0, 0.0,
  0.0, 1.0, 0.0,
  0.0, 0.0,-1.0,
  1.0, 0.0, 0.0,
  0.0, 0.0, 1.0,
  -1.0, 0.0, 0.0
);
my $norms = OpenGL::Array->new_list(GL_FLOAT,@norms);

my @colors =
(
  0.9,0.2,0.2,.75,
  0.9,0.2,0.2,.75,
  0.9,0.2,0.2,.75,
  0.9,0.2,0.2,.75,

  0.5,0.5,0.5,.5,
  0.5,0.5,0.5,.5,
  0.5,0.5,0.5,.5,
  0.5,0.5,0.5,.5,

  0.2,0.9,0.2,.5,
  0.2,0.9,0.2,.5,
  0.2,0.9,0.2,.5,
  0.2,0.9,0.2,.5,

  0.2,0.2,0.9,.25,
  0.2,0.2,0.9,.25,
  0.2,0.2,0.9,.25,
  0.2,0.2,0.9,.25,

  0.9, 0.2, 0.2, 0.5,
  0.2, 0.9, 0.2, 0.5,
  0.2, 0.2, 0.9, 0.5,
  0.1, 0.1, 0.1, 0.5,

  0.9,0.9,0.2,0.0,
  0.9,0.9,0.2,0.66,
  0.9,0.9,0.2,1.0,
  0.9,0.9,0.2,0.33
);
my $colors = OpenGL::Array->new_list(GL_FLOAT,@colors);

my @rainbow =
(
  0.9, 0.2, 0.2, 0.5,
  0.2, 0.9, 0.2, 0.5,
  0.2, 0.2, 0.9, 0.5,
  0.1, 0.1, 0.1, 0.5
);

my $rainbow = OpenGL::Array->new_list(GL_FLOAT,@rainbow);
my $rainbow_offset = 64;
my @rainbow_inc;

my @texcoords =
(
  0.005, 0.005,
  0.995, 0.005,
  0.995, 0.995,
  0.005, 0.995,

  0.005, 0.005,
  0.995, 0.005,
  0.995, 0.995,
  0.005, 0.995,

  0.005, 0.005,
  0.995, 0.005,
  0.995, 0.995,
  0.005, 0.995,

  0.005, 0.005,
  0.995, 0.005,
  0.995, 0.995,
  0.005, 0.995,

  0.005, 0.005,
  0.995, 0.005,
  0.995, 0.995,
  0.005, 0.995,

  0.005, 0.005,
  0.995, 0.005,
  0.995, 0.995,
  0.005, 0.995,


);

my @jnk = (

  0.800, 0.800,
  0.200, 0.800,
  0.200, 0.200,
  0.800, 0.200,

  0.005, 1.995,
  0.005, 0.005,
  1.995, 0.005,
  1.995, 1.995,

  0.995, 0.005,
  2.995, 2.995,
  0.005, 0.995,
  -1.995, -1.995,

  0.995, 0.005,
  0.995, 0.995,
  0.005, 0.995,
  0.005, 0.005,

  -0.5, -0.5,
  1.5, -0.5,
  1.5, 1.5,
  -0.5, 1.5,

  0.005, 0.005,
  0.995, 0.005,
  0.995, 0.995,
  0.005, 0.995
);
my $texcoords = OpenGL::Array->new_list(GL_FLOAT,@texcoords);

my @indices = (0..23);
my $indices = OpenGL::Array->new_list(GL_UNSIGNED_INT,@indices);

my @xform =
(
  1.0, 0.0, 0.0, 0.0,
  0.0, 1.0, 0.0, 0.0,
  0.0, 0.0, 1.0, 0.0,
  0.0, 0.0, 0.0, 1.0
);
my $xform = OpenGL::Array->new_list(GL_FLOAT,@xform);


# ------
# Frames per second (FPS) statistic variables and routine.

use constant CLOCKS_PER_SEC => $hasHires ? 1000 : 1;
use constant FRAME_RATE_SAMPLES => 50;

my $FrameCount = 0;
my $FrameRate = 0;
my $last=0;

my ( @cone,
     @coneDensity,
     @coneHeight,
     @conecolors,
     @conePlaces,
     @densityRange,
     @heightRange );

BEGIN {

$texture = 0;
$X_Rot   =  0.0;
$Y_Rot   =  0.0;
$X_Speed =  0.01;
$Y_Speed =  0.01;
$Z_Off   = -13.0;
$saveZ   = -10.0;
$gSpeed_Increment = 0.01;
$gState  = EARTH;

$nextTex   = 0;
$nextPhase = 0;

@cone        = (0,0,0,          0,0,0,          0,0,0);
@coneDensity = (0x33,0x33,0x33, 0x33,0x33,0x33, 0x33,0x33,0x33);
@coneHeight  = (2.0, 2.0, 2.0,   2.0, 2.0, 2.0,  2.0, 2.0, 2.0 );

@densityRange = (   0x11, 0x22, 0x22, 0x33,
		    0x33, 0x44, 0x50, 0x55,
		    0x65, 0x77, 0x88, 0x99,
		    0xAA, 0xBB, 0xCC, 0xCC );

@heightRange = (1.0, 1.05, 1.1, 1.15,
                1.2, 1.25, 1.3, 1.35,
                1.4, 1.45, 1.5, 1.55,
                1.6, 1.7, 1.8, 1.9 );


@conecolors = (
  [0xFF,0x22,0x22],
  [0xFF,0x88,0x22],
  [0xFF,0xFF,0x22],
  [0x22,0xFF,0x22],
  [0x88,0xFF,0x88],
  [0x22,0xFF,0xFF],
  [0x22,0x88,0xFF],
  [0xFF,0x22,0x88],
  [0x88,0x22,0xFF] );
}
@conePlaces = (
  [ -0.7, 0.8, -1.3 ],
  [ 0.7, 0.0, 0.0 ],
  [ 0.7, 0.0, 0.0 ],
  [ -1.4, -0.8, 0.0 ],
  [ 0.7, 0.0, 0.0 ],
  [ 0.7, 0.0, 0.0 ],
  [ -1.4, -0.8, 0.0 ],
  [ 0.7, 0.0, 0.0 ],
  [ 0.7, 0.0, 0.0 ],
  );

# OPEN SOUND CONTROL STUFF

use Net::OpenSoundControl::Server;
my $oscListen;
my $fc;
my $server;

sub oscListener {
	$server = Net::OpenSoundControl::Server->new(
		  Port => 57120, Handler => \&oscmsg)
	       or die "Could not start OSC listener: $@\n";
	$server->setupSelect();
	$oscListen = 1;
    }

sub oscStop {
        $oscListen = 0;
        if ($server)
	{
	    $server->stoploop();
	    $server->close();
	    $server = undef;
	}
    }

sub after
{
    if (defined($gDoFunc))
    {
	print "After is already in use\n";
    }
    else
    {
	my $delta = shift;
	$gDoTime = time() + $delta;
	$gDoFunc = shift;
	@gDoArgs = @_;
    }
}

sub testafter
{
   if ($gDoTime && time() >= $gDoTime)
   {
       my $gf = $gDoFunc;
       $gDoFunc = undef;
       $gf->(@gDoArgs);
       # no new after() was called inside the called function
       if (!defined($gDoFunc))
       {
	   $gDoTime = undef;
	   @gDoArgs = ();
       }
   }
}

sub computeRange
{
    my $i = shift;
#    print "Z_Off $Z_Off  gIHeight = $gIHeight[$i]\n";
    my $deg = rad2deg(atan2(-$Z_Off, $gIHeight[$i]));
    $gMaxXRot[$i] = 90 - $deg;
    $gMinXRot[$i] = $deg - 90;
    $deg = rad2deg(atan2(-$Z_Off, $gIWidth[$i]));
    $gMaxYRot[$i] = 90 - $deg;
    $gMinYRot[$i] = $deg - 90;
    if ($i == 0)
    {
    $gMaxXRot[0] = 15 + 45* (1 - (abs($Z_Off)/12));
    $gMinXRot[0] = -15 - 45* (1 - (abs($Z_Off)/12));
    $gMaxYRot[0] = 15 + 45* (1 - (abs($Z_Off)/12));
    $gMinYRot[0] = -15 - 45* (1 - (abs($Z_Off)/12));
    }
}

sub initRanges
{
    if ($gState & EARTH ) { earthRanges();}
    else                  { moonRanges(); }
}

sub moonRanges
{
  $gMinZ[0] =  0.5;
  $gMaxZ[0] = -15;
  computeRange(0);

  for(1..5)
  {
    $gMinZ[$_] = 0.5;
    $gMaxZ[$_] = -1;
    computeRange($_);
  }
}

sub earthRanges
{
  $gMinZ[0] = -30;
  $gMaxZ[0] = -15;
  computeRange(0);

  for(1..5)
  {
    $gMinZ[$_] = -30;
    $gMaxZ[$_] = -28;
    computeRange($_);
  }
}

sub cubeRotSpeed
{
      $X_Speed = shift;
      $Y_Speed = shift;
}

my $grSpeed = 0;

sub startRocking
{
    $Y_Speed = 0.2;
    $grSpeed = 0.0;
    after(1, \&rockRight);
}
sub rockLeft
{
    $grSpeed += .02;
    $Y_Speed = 0.2 + $grSpeed;
    after(2, \&rockRight);
}

sub rockRight
{
    $Y_Speed = -0.2 - $grSpeed;
    after(2, \&rockLeft);
}


sub oscmsg
{
    my ($type,undef,$square,undef,$level) = $server->readone();
    if ( $type eq "/activity" ) { $cone[$square] += $level*2; };
    if ($fc++ % 8 == 0 )
    {
	for (0..8) {
	    if    ( $cone[$_] > 15) { $cone[$_] = 15; }
	    elsif ( $cone[$_] > 7 ) { $cone[$_] -=3;  }
	    elsif ( $cone[$_] > 2 ) { $cone[$_] -=2;  }
	    elsif ( $cone[$_] > 0 ) { $cone[$_]--;    }
	    $coneDensity[$_] = $densityRange[$cone[$_]];
	    $coneHeight[$_] =  $heightRange[$cone[$_]];
	} 
    }
    if ($fc % 50 == 0 )
    {
	rebuildOneTexture();
    }
}

sub flicker
{
    for my $i (0..8)
    {
	if ($cone[$i])
	{
	    if ($cone[$i] > (rand() * 20 + 10))
	    {
		$cone[$i] = 0;
	    } else {
		$cone[$i] -= 1 if (rand() > 0.95);
		$cone[$i] -= 2 if (rand() < 0.05);
                $cone[$i] = 0 if $cone[$i] < 0;
		$cone[$i]++ if (rand() > 0.85);
		my $age = int($cone[$i]/5);
		$coneDensity[$i] = $densityRange[$age];
		$coneHeight[$i] = 1.5 + 0.2 * $age;
	    }
	} else {
	    $cone[$i] = 1 if (rand() > 0.993);
	}
    }
}

sub ourDoFPS
{
  if (++$FrameCount >= FRAME_RATE_SAMPLES)
  {
     my $now = $hasHires ? gettimeofday() : time(); # clock();
     my $delta= ($now - $last);
     $last = $now;

     $FrameRate = FRAME_RATE_SAMPLES / ($delta || 1);
     $FrameCount = 0;
  }
}

# ------
# String rendering routine; leverages on GLUT routine.

sub ourPrintString
{
  my ($font, $str) = @_;
  my @c = split '', $str;

  for(@c)
  {
    glutBitmapCharacter($font, ord $_);
  }
}


# ------
# Does everything needed before losing control to the main
# OpenGL event loop.

sub ourInit
{
  my ($Width, $Height) = @_;
  $fc = 0;

  # Set initial colors for rainbow face
  for (my $k=0; $k<16; $k++)
  {
    $rainbow[$k] = rand(1.0);
    $rainbow_inc[$k] = 0.01 - rand(0.02);
  }

  # Initialize VBOs if supported
  if ($hasVBO)
  {
    ($VertexObjID,$NormalObjID,$ColorObjID,$TexCoordObjID,$IndexObjID) =
      glGenBuffersARB_p(5);

    #glBindBufferARB(GL_ARRAY_BUFFER_ARB, $VertexObjID);

    $verts->bind($VertexObjID);
    glBufferDataARB_p(GL_ARRAY_BUFFER_ARB, $verts, GL_STATIC_DRAW_ARB);
    glVertexPointer_c(3, GL_FLOAT, 0, 0);

    #glBindBufferARB(GL_ARRAY_BUFFER_ARB, $NormalObjID);

    $norms->bind($NormalObjID);
    glBufferDataARB_p(GL_ARRAY_BUFFER_ARB, $norms, GL_STATIC_DRAW_ARB);
    glNormalPointer_c(GL_FLOAT, 0, 0);

    #glBindBufferARB(GL_ARRAY_BUFFER_ARB, $ColorObjID);

    $colors->bind($ColorObjID);
    glBufferDataARB_p(GL_ARRAY_BUFFER_ARB, $colors, GL_DYNAMIC_DRAW_ARB);
    $rainbow->assign(0,@rainbow);
    glBufferSubDataARB_p(GL_ARRAY_BUFFER_ARB, $rainbow_offset, $rainbow);
    glColorPointer_c(4, GL_FLOAT, 0, 0);

    #glBindBufferARB(GL_ARRAY_BUFFER_ARB, $TexCoordObjID);

    $texcoords->bind($TexCoordObjID);
    glBufferDataARB_p(GL_ARRAY_BUFFER_ARB, $texcoords, GL_STATIC_DRAW_ARB);
    glTexCoordPointer_c(2, GL_FLOAT, 0, 0);

    #glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, $IndexObjID);

    $indices->bind($IndexObjID);
    glBufferDataARB_p(GL_ELEMENT_ARRAY_BUFFER_ARB, $indices, GL_STATIC_DRAW_ARB);
  }

  # Build texture.
  ourBuildTextures(0..5);
  glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL);
  ourInitShaders();

  # Initialize rendering parameters
  glEnable(GL_TEXTURE_2D);
  glDisable(GL_LIGHTING);
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_BLEND);

  # Color to clear color buffer to.
  glClearColor(0.0, 0.0, 0.0, 0.0);

  # Depth to clear depth buffer to; type of test.
  glClearDepth(1.0);
  glDepthFunc(GL_LESS);

  # Enables Smooth Color Shading; try GL_FLAT for (lack of) fun.
  glShadeModel(GL_SMOOTH);

  # Load up the correct perspective matrix; using a callback directly.
  cbResizeScene($Width, $Height);

  # Set up a light, turn it on.
  glLightfv_p(GL_LIGHT1, GL_POSITION, @Light_Position);
  glLightfv_p(GL_LIGHT1, GL_AMBIENT,  @Light_Ambient);
  glLightfv_p(GL_LIGHT1, GL_DIFFUSE,  @Light_Diffuse);
  glEnable(GL_LIGHT1);

  # A handy trick -- have surface material mirror the color.
  glColorMaterial(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE);
  glEnable(GL_COLOR_MATERIAL);
 
  oscListener();
}


# ------
# Function to build a simple full-color texture with alpha channel,
# and then create mipmaps.
# Also sets up FBO texture and Vertex/Fragment programs.

sub ourBuildTextures
{
  my $gluerr;
  my $tex;

    my @img;
    my(@eng,@ver);

for my $i (@_)
 {

  # Build Image Texture
  ($TextureID_image[$i],$TextureID_FBO[$i]) = glGenTextures_p(2);

  my $filename = "$idir/$Tex_Files[$i]";
  # Use OpenGL::Image to load texture
#  print "gState = $gState: opening $filename\n";
  if ($hasImage && -e $filename)
  {
      print "loading $filename\n";
	$img[$i] = new OpenGL::Image(source=>$filename);
	($eng[$i],$ver[$i]) = $img[$i]->Get('engine','version');

    ($Tex_Width,$Tex_Height) = $img[$i]->Get('width','height');

     my $maxdim = $Tex_Width > $Tex_Height ? $Tex_Width : $Tex_Height;
     if ($maxdim == $Tex_Width)
     {
	 $gIWidth[$i] = 1.0;
	 $gIHeight[$i] = $Tex_Height/$Tex_Width;
     } else {
	 $gIHeight[$i] = 1.0;
	 $gIWidth[$i] = $Tex_Width/$Tex_Height;
     }
	

    my $alpha = $img[$i]->Get('alpha') ? 'has' : 'no';

    ($Tex_Type,$Tex_Format,$Tex_Size) = 
      $img[$i]->Get('gl_internalformat','gl_format','gl_type');

    # Use OGA for testing
    $Tex_Image[$i] = $img[$i];
    $Tex_Pixels[$i] = $img[$i]->GetArray();
  }
  glBindTexture(GL_TEXTURE_2D, $TextureID_image[$i]);


  # Use MipMap
  if ($useMipMap)
  {
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
      GL_NEAREST_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
      GL_NEAREST_MIPMAP_LINEAR);

    # The GLU library helps us build MipMaps for our texture.
    if (defined($Tex_Pixels[$i]) && defined($Tex_Pixels[$i]->ptr())
        && 
       ($gluerr = gluBuild2DMipmaps_c(GL_TEXTURE_2D, $Tex_Type,
      $Tex_Width, $Tex_Height, $Tex_Format, $Tex_Size,
      $Tex_Pixels[$i]->ptr())))
    {
      printf STDERR "GLULib%s\n", gluErrorString($gluerr);
      exit(-1);
    }
  }

 } # end for $i (0..5)

# Now that we have the image sizes, we can
# do the zoom/rotation constraint calculations

  initRanges(); 

  glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL);
}

sub rebuildOneTexture
{
  my $gluerr;
  my $tex;
  my @img;
  my(@eng,@ver);

  my $i = $nextTex % 6;
  my $filename = $idir. ($gState&EARTH?"/earth/":"/moon/").$Tex_Files[$i];
  if ($nextPhase == 0)
  {
#      ($rcTID, $rcIDFBO) = ($TextureID_image[$i],$TextureID_FBO[$i]);
#      ($newTID,$newIDFBO) = glGenTextures_p(2);
      if ($hasImage && -e $filename)
      {
	$img[$i] = new OpenGL::Image(source=>$filename);
	($eng[$i],$ver[$i]) = $img[$i]->Get('engine','version');

    ($Tex_Width,$Tex_Height) = $img[$i]->Get('width','height');
    my $alpha = $img[$i]->Get('alpha') ? 'has' : 'no';

    ($Tex_Type,$Tex_Format,$Tex_Size) = 
      $img[$i]->Get('gl_internalformat','gl_format','gl_type');

    # Use OGA for testing
    $Tex_Image[$i] = $img[$i];
    $Tex_Pixels[$i] = $img[$i]->GetArray();
    }
      $nextPhase = 1;
      print "phase 0 complete\n";
  }
  elsif ($nextPhase == 1)
  {
#      glBindTexture(GL_TEXTURE_2D, $newTID);
      $nextPhase = 2;
      print "phase 1 complete\n";
  }
  elsif ($nextPhase == 2)
  {
      # Use MipMap
      # if ($useMipMap)
      if (0)
      {
	  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			  GL_NEAREST_MIPMAP_LINEAR);
	  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			  GL_NEAREST_MIPMAP_LINEAR);
	  
	  # The GLU library helps us build MipMaps for our texture.
	  if (defined($Tex_Pixels[$i]) && defined($Tex_Pixels[$i]->ptr())
	      && 
	      ($gluerr = gluBuild2DMipmaps_c(GL_TEXTURE_2D, $Tex_Type,
               $Tex_Width, $Tex_Height, $Tex_Format, $Tex_Size,
               $Tex_Pixels[$i]->ptr())))
	  {
	      printf STDERR "GLULib%s\n", gluErrorString($gluerr);
	      exit(-1);
	  }
      }
#      ($TextureID_image[$i],$TextureID_FBO[$i]) = ($newTID, $newIDFBO);
#      glDeleteTextures_p($rcTID, $rcIDFBO);
      $nextTex++;
      $nextPhase = 0;
      print "phase 2 complete\n";
  }
}

sub ourSelectTexture
{
 my $i = shift;
 glBindTexture(GL_TEXTURE_2D,$FBO_On ? $TextureID_FBO[$i]:$TextureID_image[$i]);
}

sub ourInitShaders
{
  # Setup Vertex/Fragment Programs to render FBO texture

  # Use OpenGL::Shader
  if ($hasShader && ($Shader = new OpenGL::Shader()))
  {
    my $type = $Shader->GetType();
    my $ext = lc($type);

    my $stat = $Shader->LoadFiles("fragment.$ext","vertex.$ext");
    if (!$stat)
    {
      my $ver = $Shader->GetVersion();
      print "Using OpenGL::Shader('$type') v$ver\n";
      return;
    }
    else
    {
#     print "$stat\n";
    }
  }

}

sub cbRenderOnce
{
  # Enables, disables or otherwise adjusts as
  # appropriate for our current settings.

  if ($Texture_On)
  {
    glEnable(GL_TEXTURE_2D);
  }
  else
  {
    glDisable(GL_TEXTURE_2D);
  }
  if ($Light_On)
  {
    glEnable(GL_LIGHTING);
  }
  else
  {
    glDisable(GL_LIGHTING);
  }
  if ($Alpha_Add)
  {
#    glBlendFunc(GL_SRC_ALPHA,GL_ONE);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  }
  else
  {
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  }
  # If we're blending, we don'$t want z-buffering.
  if ($Blend_On)
  {
    glDisable(GL_DEPTH_TEST);
  }
  else
  {
    glEnable(GL_DEPTH_TEST);
  }
  # Needs ModelView matrix to move our model around.
  glMatrixMode(GL_MODELVIEW);
}
# ------
# Routine which actually does the drawing

sub cbRenderScene
{
  my $i = $texture%6;
  $gSwitched++;
  testafter();

  glLoadIdentity();              # Reset to 0,0,0; no rotation, no scaling.
  glTranslatef(0.0,0.0,0.0); # $Z_Off);  # Move the object back from the screen.
  computeRotation($i);
  glRotatef($X_Rot,1.0,0.0,0.0);
  glRotatef($Y_Rot,0.0,1.0,0.0); # Rotate the (previously) calculated amount.
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);  # Clear color/depth buffers.
  glEnable(GL_COLOR_MATERIAL);
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);

 # Render plane with selected texture
#  newOffset($Z_Off);
  ourSelectTexture($i);
  glDrawArrays(GL_QUADS, 0, 4);  # only one plane
  ourSelectTexture($i+1);
  glDrawArrays(GL_QUADS, 4, 4);  # only one plane
  ourSelectTexture(4);
  glDrawArrays(GL_QUADS, 8, 4);  # only one plane


  glBindTexture(GL_TEXTURE_2D,0);  # Go to default texture to see the colors!
  glDisable(GL_COLOR_MATERIAL);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);
  glDisableClientState(GL_NORMAL_ARRAY);
  glDisableClientState(GL_VERTEX_ARRAY);


  glutSwapBuffers();
}


# Rotation limits are determined by the size of the
# picture and the distance of the viewer. The viewer
# should never see the edges of the pictures.

sub computeRotation
{
  my $i = shift;
  $X_Rot += $X_Speed;
  $Y_Rot += $Y_Speed;
#  print "XRot = [$X_Rot] YRot = [$Y_Rot]\n";
  return;

  if ( $X_Speed > 0 ) {
      if ($X_Rot < $gMaxXRot[$i]) { $X_Rot += $X_Speed; }
      else                        { $X_Rot  = $gMaxXRot[$i]; $X_Speed = 0.0; }
  } else {
      if ($X_Rot > $gMinXRot[$i]) { $X_Rot += $X_Speed; }
      else                        { $X_Rot  = $gMinXRot[$i]; $X_Speed = 0.0; }
  }
  if ( $Y_Speed > 0 ) {
      if ($Y_Rot < $gMaxYRot[$i]) { $Y_Rot += $Y_Speed; }
      else                        { $Y_Rot  = $gMaxYRot[$i]; $Y_Speed = 0.0; }
  }
  else  {
      if ($Y_Rot > $gMinYRot[$i]) { $Y_Rot += $Y_Speed; }
      else                        { $Y_Rot  = $gMinYRot[$i]; $Y_Speed = 0.0; }
  }
  if ($X_Rot =~ /i/ || $Y_Rot =~ /i/)
  {
    print "Complexity! XRot = [$X_Rot] YRot = [$Y_Rot]\n";
    exit(0);
  }
}

sub nextposition
{
    my $i = shift;
    if    ($i == 0) { glTranslated(-0.7, 0.8, -1.3); }
    elsif ($i == 1) { glTranslated(0.7, 0.0, 0.0);   }
    elsif ($i == 2) { glTranslated(0.7, 0.0, 0.0);   }
    elsif ($i == 3) { glTranslated(-1.4, -0.8, 0.0); }
    elsif ($i == 4) { glTranslated(0.7, 0.0, 0.0);   }
    elsif ($i == 5) { glTranslated(0.7, 0.0, 0.0);   }
    elsif ($i == 6) { glTranslated(-1.4, -0.8, 0.0); }
    elsif ($i == 7) { glTranslated(0.7, 0.0, 0.0);   }
    elsif ($i == 8) { glTranslated(0.7, 0.0, 0.0);   }
}


# Display inset
sub Inset
{
  my($w,$h) = @_;

  my $Capture_X = int(($w - $Inset_Width) / 2);
  my $Capture_Y = int(($h - $Inset_Height) / 2);
  my $Inset_X = $w - ($Inset_Width + 2);
  my $Inset_Y = $h - ($Inset_Height + 2);

  # Using OpenGL::Image and ImageMagick to read/modify/draw pixels
  if ($hasIM_635)
  {
    my $frame = new OpenGL::Image(engine=>'Magick',
      width=>$Inset_Width, height=>$Inset_Height);
    my($fmt,$size) = $frame->Get('gl_format','gl_type');

    glReadPixels_c( $Capture_X, $Capture_Y, $Inset_Width, $Inset_Height,
      $fmt, $size, $frame->Ptr() );
    $frame->Sync();

    # For grins, use ImageMagick to modify the inset
    $frame->Native->Blur(radius=>2,sigma=>2);

    glRasterPos2f( $Inset_X, $Inset_Y );
    glDrawPixels_c( $Inset_Width, $Inset_Height, $fmt, $size, $frame->Ptr() );
  }
  # Fastest approach
  else
  {
    my $len = $Inset_Width * $Inset_Height * 4;
    my $oga = new OpenGL::Array($len,GL_UNSIGNED_BYTE);

    glReadPixels_c( $Capture_X, $Capture_Y, $Inset_Width, $Inset_Height,
      GL_RGBA, GL_UNSIGNED_BYTE, $oga->ptr() );
    glRasterPos2f( $Inset_X, $Inset_Y );
    glDrawPixels_c( $Inset_Width, $Inset_Height, GL_RGBA, GL_UNSIGNED_BYTE, $oga->ptr() );
  }
}

# Capture/save window
sub Save
{
  my($w,$h,$file) = @_;

  if ($hasImage)
  {
    my $frame = new OpenGL::Image(width=>$w, height=>$h);
    my($fmt,$size) = $frame->Get('gl_format','gl_type');

    glReadPixels_c( 0, 0, $w, $h, $fmt, $size, $frame->Ptr() );
    $frame->Save($file);
  }
  else
  {
    print "Need OpenGL::Image and ImageMagick 6.3.5 or newer for file capture!\n";
  }
}

# Cleanup routine
sub ourCleanup
{
  # Disable app
  glutHideWindow();
  glutKeyboardFunc();
  glutSpecialFunc();
  glutIdleFunc();
  glutReshapeFunc();

  if ($hasFBO)
  {
   for my $i (0..5)
   {
    # Release resources
    glBindRenderbufferEXT( GL_RENDERBUFFER_EXT, $i );
    glBindFramebufferEXT( GL_FRAMEBUFFER_EXT, $i );
    glDeleteRenderbuffersEXT_p( $RenderBufferID[$i] ) if ($RenderBufferID[$i]);
    glDeleteFramebuffersEXT_p( $FrameBufferID[$i] ) if ($FrameBufferID[$i]);
   }
  }

  if ($Shader)
  {
    undef($Shader);
  }
  elsif ($hasFragProg)
  {
    glBindProgramARB(GL_VERTEX_PROGRAM_ARB, 0);
    glDeleteProgramsARB_p( $VertexProgID ) if ($VertexProgID);

    glBindProgramARB(GL_FRAGMENT_PROGRAM_ARB, 0);
    glDeleteProgramsARB_p( $FragProgID ) if ($FragProgID);
  }

  if ($hasVBO)
  {
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
    glDeleteBuffersARB_p($VertexObjID) if ($VertexObjID);
    glDeleteBuffersARB_p($NormalObjID) if ($NormalObjID);
    glDeleteBuffersARB_p($ColorObjID) if ($ColorObjID);
    glDeleteBuffersARB_p($TexCoordObjID) if ($TexCoordObjID);

    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
    glDeleteBuffersARB_p($IndexObjID) if ($IndexObjID);
  }

  for my $l (0..5)
  {
      glDeleteTextures_p($TextureID_image[$l],$TextureID_FBO[$l]);
  }

  # Now you can destroy window
  glutDestroyWindow($Window_ID);
}

# ------
# Callback function called when a normal $key is pressed.

sub cbKeyPressed
{
  my $key = shift;
  my $c = uc chr $key;
  if ($key == 27 or $c eq 'Q')
  {
    ourCleanup();
    exit(0);
  }
  elsif ($c eq 'B')
  {
    $Blend_On = !$Blend_On;
    if (!$Blend_On)
    {
      glDisable(GL_BLEND);
    }
    else {
      glEnable(GL_BLEND);
    }
  }
  elsif ($c eq 'L')
  {
    $Light_On = !$Light_On;
  }
  elsif ($c eq 'M')
  {
    if ( ++ $Curr_TexMode > 3 )
    {
      $Curr_TexMode=0;
    }
    glTexEnvi(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,$TexModes[$Curr_TexMode]);
  }
  elsif ($c eq 'T')
  {
    $Texture_On = !$Texture_On;
  }
  elsif ($c eq 'A')
  {
    $Alpha_Add = !$Alpha_Add;
  }
  elsif ($c eq 'F' && $hasFBO)
  {
    $FBO_On = ($FBO_On+1) % 3;
    ourSelectTexture(0);
  }
  elsif ($c eq 'I')
  {
    $Inset_On = !$Inset_On;
  }
  elsif ($c eq 'S' or $key == 32)
  {
    $X_Speed=$Y_Speed=0;
  }
  elsif ($c eq 'R')
  {
    $X_Speed = -$X_Speed;
    $Y_Speed = -$Y_Speed;
  }
  elsif ($c eq 'G')
  {
    $Fullscreen_On = !$Fullscreen_On;
    if ($Fullscreen_On)
    {
      $Save_Width = $Window_Width;
      $Save_Height = $Window_Height;
      glutFullScreen();
    }
    else
    {
      $Window_Width = $Save_Width;
      $Window_Height = $Save_Height;
      glutReshapeWindow($Window_Width,$Window_Height);
    }
  }
  elsif ($c eq 'C' && $hasImage)
  {
      if ($gState&EARTH)
      {
	  $gState = MOON;
      }
      else
      {
	  $gState = EARTH;
      }
      $texture = 0;
  }
  elsif ($c eq 'Y')
  {
    if ($texture%6 == 0) 
    {
	$saveZ = $Z_Off;
    }

    $texture++;
    if ($gState == (EARTH|NEAR)) 
    {

    }
    if ($texture%6 == 0) 
    {
	$Z_Off = $saveZ;
    }
    else
    {
	$Z_Off   = $gMaxZ[$texture%6] + abs($gMaxZ[$texture%6]/5);
    }
    computeRange($texture%6);
  }
  else
  {
    printf "KP: No action for %d.\n", $key;
  }
}

# ------
# Callback Function called when a special $key is pressed.

sub cbSpecialKeyPressed
{
  my $key = shift;
  my $tid = $texture%6;

  if ($key == GLUT_KEY_PAGE_UP)
  {
      if ( ! $gState&EARTH )
      {
	  ZoomOut($tid);
	  computeRange($tid);
      }
      else
      {
	  ZoomIn($tid);
          computeRange($tid);
      }
  }
  elsif ($key == GLUT_KEY_PAGE_DOWN)
  {
      if ( ! $gState&EARTH )
      {
	  ZoomIn($tid);
          computeRange($tid);
      }
      else
      {
	  ZoomOut($tid);
          computeRange($tid);
      }
  }
  elsif ($key == GLUT_KEY_UP)
  {
    $X_Speed -= $gSpeed_Increment;
  }
  elsif ($key == GLUT_KEY_DOWN)
  {
    $X_Speed += $gSpeed_Increment;
  }
  elsif ($key == GLUT_KEY_LEFT)
  {
    $Y_Speed -= $gSpeed_Increment;
  }
  elsif ($key == GLUT_KEY_RIGHT)
  {
    $Y_Speed += $gSpeed_Increment;
  }
  else
  {
    printf "SKP: No action for %d.\n", $key;
  }
}

# NOTE Z is negative so > and < are reversed

sub ZoomOut
{
    my $tid = shift;
    if ($tid == 0)   # PLANETARY RANGE
    {
	$Z_Off -= 0.04; # Faster in Planetary mode
	return;
	if ($gSwitched > 1000)
	{
	    if (!($gState&EARTH) && $Z_Off <= ( $gMaxZ[$tid] + 0.5))
	    {
		$gSwitched = 0;
		$gState = EARTH;
		initRanges();
		print "switching to earth $Z_Off <= (max) $gMaxZ[$tid]\n";
		for my $l (0..5)
		{
		    glDeleteTextures_p($TextureID_image[$l],$TextureID_FBO[$l]);
		}
		$texture = 0;
	    }
	    elsif (($gState&EARTH) && $Z_Off >= $gMinZ[$tid])
	    {
		$gSwitched = 0;
	$gState = MOON;
		initRanges();
		print "switching to moon $Z_Off <= (min) $gMinZ[$tid]\n";
		for my $k (0..5)
		{
		 glDeleteTextures_p($TextureID_image[$k],$TextureID_FBO[$k]);
		}
		$texture = 0;
	    }
	} # END $gSwitched > 1000
    } else { # END PLANETARY RANGE
	$Z_Off -= 0.02;
	return;
	if ($Z_Off < $gMaxZ[$tid])
	{
#	print "Z_Off at Maximum limit $Z_Off\n";
	    if ($tid == 1) 	# back to full moon/earth view
	    {
		$texture--;
	    } 
	    return;
	}
    } # END PROVINCIAL RANGE 
}


sub ZoomIn
{
    my $tid = shift;
    if ($tid == 0) {
	$Z_Off += 0.1;
    } else {
	$Z_Off += 0.05;
    }
    print "Z_Off = $Z_Off\n";
    return;
    if ($Z_Off > $gMinZ[$tid])
    {
#	print "Z_Off at minumum limit $Z_Off\n";
        if ($tid == 0) 	{ $texture++; }
	return;
    }
}

# ------
# Callback routine executed whenever our window is resized.  Lets us
# request the newly appropriate perspective projection matrix for
# our needs.  Try removing the gluPerspective() call to see what happens.

sub cbResizeScene
{
  my ($Width, $Height) = @_;

  # Let's not core dump, no matter what.
  $Height = 1 if ($Height == 0);

  glViewport(0, 0, $Width, $Height);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(45.0,$Width/$Height,0.1,100.0);

  glMatrixMode(GL_MODELVIEW);

  $Window_Width  = $Width;
  $Window_Height = $Height;
}



chdir("C:/cygwin/home/peter/openGL/apollo");

# ------
# The main() function.  Inits OpenGL.  Calls our own init function,
# then passes control onto OpenGL.

eval {glutInit(); 1} or die qq
{
This test requires GLUT:
If you have X installed, you can try the scripts in ./examples/
Most of them do not use GLUT.

It is recommended that you install GLUT for improved Makefile.PL
configuration, installation and debugging.
};

# To see OpenGL drawing, take out the GLUT_DOUBLE request.
glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH | GLUT_ALPHA);
glutInitWindowSize($Window_Width, $Window_Height);

# Open a window
$Window_ID = glutCreateWindow( $PROGRAM_TITLE );

# Get OpenGL Info
#print "\n";
#print PROGRAM_TITLE;
#print ' (using hires timer)' if ($hasHires);
#print "\n\n";

my $version = glGetString(GL_VERSION);
my $vendor = glGetString(GL_VENDOR);
my $renderer = glGetString(GL_RENDERER);
#print "Using POGL v$OpenGL::BUILD_VERSION\n";
#print "OpenGL installation: $version\n$vendor\n$renderer\n\n";

#print "Installed extensions (* implemented in the module):\n";
my $extensions = glGetString(GL_EXTENSIONS);
my @extensions = split(' ',$extensions);

#foreach my $ext (sort @extensions)
#{
#  my $stat = OpenGL::glpCheckExtension($ext);
#  printf("%s $ext\n",$stat?' ':'*');
#  print("    $stat\n") if ($stat && $stat !~ m|^$ext |);
#}

if (!OpenGL::glpCheckExtension('GL_ARB_vertex_buffer_object'))
{
  $hasVBO = 1;
}

if (!OpenGL::glpCheckExtension('GL_EXT_framebuffer_object'))
{
  $hasFBO = 1;
  $FBO_On = 1;

  if (!OpenGL::glpCheckExtension('GL_ARB_fragment_program'))
  {
    $hasFragProg = 1;
    $FBO_On++;
  }
}

sub newOffset
{
   my $newZ = shift;
   $verts = OpenGL::Array->new_list(GL_FLOAT,@verts);
   for my $i (0..3)
   {
       $verts[3*$i+2] = -$newZ;
       $verts[12+3*$i+2] = $newZ;
   }
    $verts->bind($VertexObjID);
    glBufferDataARB_p(GL_ARRAY_BUFFER_ARB, $verts, GL_STATIC_DRAW_ARB);
    glVertexPointer_c(3, GL_FLOAT, 0, 0);
}


# Register the callback function to do the drawing.
glutDisplayFunc(\&cbRenderScene);

# If there's nothing to do, draw.
glutIdleFunc(\&cbRenderScene);

# It's a good idea to know when our window's resized.
glutReshapeFunc(\&cbResizeScene);

# And let's get some keyboard input.
glutKeyboardFunc(\&cbKeyPressed);
glutSpecialFunc(\&cbSpecialKeyPressed);

# OK, OpenGL's ready to go.  Let's call our own init function.
ourInit($Window_Width, $Window_Height);

# Print out a bit of help dialog.
# print qq
my $xfg = qq
{
Hold down arrow keys to rotate, 'r' to reverse, 's' to stop.
Page up/down will move cube away from/towards camera.
Use first letter of shown display mode settings to alter.
Press 'c' to capture/save a RGBA targa file.
'q' or [Esc] to quit; OpenGL window must have focus for input.

};

# Pass off control to OpenGL.
# Above functions are called as appropriate.

# Do the stuff we only need to do once.
# This code originally appeared in cbRenderScene()
# but I wanted to streamline that routine.

  cbRenderOnce(); 

  # After nine seconds, halt the cube rotation
  # around the X and Y axis.

#  after(3, \&cubeRotSpeed, 0.0, 0.0);

  glutMainLoop();

__END__

