//
//	Code repository for GPU noise development blog
//	http://briansharpe.wordpress.com
//	https://github.com/BrianSharpe
//
//	I'm not one for copywrites.  Use the code however you wish.
//	All I ask is that credit be given back to the blog or myself when appropriate.
//	And also to let me know if you come up with any changes, improvements, thoughts or interesting uses for this stuff. :)
//	Thanks!
//
//	Brian Sharpe
//	brisharpe@yahoo.com
//	http://briansharpe.wordpress.com
//	https://github.com/BrianSharpe
//


//
//	NoiseLib TODO
//
//	1) Ensure portability across different cards
//	2) 16bit and 24bit implementations of hashes and noises
//	3) Lift various noise implementations out to individual self-contained files
//	4) Implement texture-based versions
//	5) 4D noises
//

//
//	Permutation polynomial idea is from Stefan Gustavson's and Ian McEwan's work at...
//	http://github.com/ashima/webgl-noise
//	http://www.itn.liu.se/~stegu/GLSL-cellular
//
//	http://briansharpe.wordpress.com/2011/10/01/gpu-texture-free-noise/
//
vec4 SGPP_coord_prepare(vec4 x) { return x - floor(x * ( 1.0 / 289.0 )) * 289.0; }
vec3 SGPP_coord_prepare(vec3 x) { return x - floor(x * ( 1.0 / 289.0 )) * 289.0; }
vec4 SGPP_permute(vec4 x) { return fract( x * ( ( 34.0 / 289.0 ) * x + ( 1.0 / 289.0 ) ) ) * 289.0; }
vec4 SGPP_resolve(vec4 x) { return fract( x * ( 7.0 / 288.0 ) ); }
vec4 SGPP_hash_2D( vec2 gridcell )		//	generates a random number for each of the 4 cell corners
{
	//    gridcell is assumed to be an integer coordinate
	vec4 hash_coord = SGPP_coord_prepare( vec4( gridcell.xy, gridcell.xy + 1.0.xx ) );
	return SGPP_resolve( SGPP_permute( SGPP_permute( hash_coord.xzxz ) + hash_coord.yyww ) );
}
void SGPP_hash_2D( vec2 gridcell, out vec4 hash_0, out vec4 hash_1 )	//	generates 2 random numbers for each of the 4 cell corners
{
	//    gridcell is assumed to be an integer coordinate
	vec4 hash_coord = SGPP_coord_prepare( vec4( gridcell.xy, gridcell.xy + 1.0.xx ) );
	hash_0 = SGPP_permute( SGPP_permute( hash_coord.xzxz ) + hash_coord.yyww );
	hash_1 = SGPP_resolve( SGPP_permute( hash_0 ) );
	hash_0 = SGPP_resolve( hash_0 );
}
void SGPP_hash_3D( vec3 gridcell, out vec4 lowz_hash, out vec4 highz_hash )		//	generates a random number for each of the 8 cell corners
{
	//    gridcell is assumed to be an integer coordinate
	gridcell = SGPP_coord_prepare( gridcell );
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, 287.5.xxx ) );
	highz_hash = SGPP_permute( SGPP_permute( vec2( gridcell.x, gridcell_inc1.x ).xyxy ) + vec2( gridcell.y, gridcell_inc1.y ).xxyy );
	lowz_hash = SGPP_resolve( SGPP_permute( highz_hash + gridcell.zzzz ) );
	highz_hash = SGPP_resolve( SGPP_permute( highz_hash + gridcell_inc1.zzzz ) );
}
void SGPP_hash_3D( 	vec3 gridcell,
					vec3 v1_mask,		//	user definable v1 and v2.  ( 0's and 1's )
					vec3 v2_mask,
					out vec4 hash_0,
					out vec4 hash_1,
					out vec4 hash_2	)		//	generates 3 random numbers for each of the 4 3D cell corners.  cell corners:  v0=0,0,0  v3=1,1,1  the other two are user definable
{
	vec3 coords0 = gridcell.xyz - floor(gridcell.xyz * ( 1.0 / 289.0 )) * 289.0;
	vec3 coords3 = mix( coords0 + 1.0.xxx, 0.0.xxx, greaterThan( coords0, 287.5.xxx ) );
	vec3 coords1 = mix( coords3, coords0, lessThan( v1_mask, 0.5.xxx ) );
	vec3 coords2 = mix( coords3, coords0, lessThan( v2_mask, 0.5.xxx ) );
	hash_2 = SGPP_permute( SGPP_permute( SGPP_permute( vec4( coords0.x, coords1.x, coords2.x, coords3.x ) ) + vec4( coords0.y, coords1.y, coords2.y, coords3.y ) ) + vec4( coords0.z, coords1.z, coords2.z, coords3.z ) );
	hash_0 = SGPP_resolve( hash_2  );
	hash_1 = SGPP_resolve( hash_2 = SGPP_permute( hash_2 ) );
	hash_2 = SGPP_resolve( SGPP_permute( hash_2 ) );
}
void SGPP_hash_3D( 	vec3 gridcell,
					out vec4 lowz_hash_0,
					out vec4 lowz_hash_1,
					out vec4 lowz_hash_2,
					out vec4 highz_hash_0,
					out vec4 highz_hash_1,
					out vec4 highz_hash_2	)	//	generates 3 random numbers for each of the 8 cell corners
{
	//    gridcell is assumed to be an integer coordinate
	gridcell = SGPP_coord_prepare( gridcell );
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, 287.5.xxx ) );
	highz_hash_2 = SGPP_permute( SGPP_permute( vec2( gridcell.x, gridcell_inc1.x ).xyxy ) + vec2( gridcell.y, gridcell_inc1.y ).xxyy );
	lowz_hash_0 = SGPP_resolve( lowz_hash_2 = SGPP_permute( highz_hash_2 + gridcell.zzzz ) );
	highz_hash_0 = SGPP_resolve( highz_hash_2 = SGPP_permute( highz_hash_2 + gridcell_inc1.zzzz ) );
	lowz_hash_1 = SGPP_resolve( lowz_hash_2 = SGPP_permute( lowz_hash_2 ) );
	highz_hash_1 = SGPP_resolve( highz_hash_2 = SGPP_permute( highz_hash_2 ) );
	lowz_hash_2 = SGPP_resolve( SGPP_permute( lowz_hash_2 ) );
	highz_hash_2 = SGPP_resolve( SGPP_permute( highz_hash_2 ) );
}


//
//	implementation of the blumblumshub hash
//	as described in MNoise paper http://www.cs.umbc.edu/~olano/papers/mNoise.pdf
//
//	http://briansharpe.wordpress.com/2011/10/01/gpu-texture-free-noise/
//
vec4 BBS_coord_prepare(vec4 x) { return x - floor(x * ( 1.0 / 61.0 )) * 61.0; }
vec3 BBS_coord_prepare(vec3 x) { return x - floor(x * ( 1.0 / 61.0 )) * 61.0; }
vec4 BBS_permute(vec4 x) { return fract( x * x * ( 1.0 / 61.0 )) * 61.0; }
vec4 BBS_permute_and_resolve(vec4 x) { return fract( x * x * ( 1.0 / 61.0 ) ); }
vec4 BBS_hash_2D( vec2 gridcell )	//	generates a random number for each of the 4 cell corners
{
	//    gridcell is assumed to be an integer coordinate
	vec4 hash_coord = BBS_coord_prepare( vec4( gridcell.xy, gridcell.xy + 1.0.xx ) );
	vec4 p = BBS_permute( hash_coord.xzxz /* * 7.0 */ ); // * 7.0 will increase variance close to origin
	return BBS_permute_and_resolve( p + hash_coord.yyww );
}
vec4 BBS_hash_hq_2D( vec2 gridcell )	//	generates a hq random number for each of the 4 cell corners
{
	//    gridcell is assumed to be an integer coordinate
	vec4 hash_coord = BBS_coord_prepare( vec4( gridcell.xy, gridcell.xy + 1.0.xx ) );
	vec4 p = BBS_permute( hash_coord.xzxz /* * 7.0 */ );  // * 7.0 will increase variance close to origin
	p = BBS_permute( p + hash_coord.yyww );
	return BBS_permute_and_resolve( p + hash_coord.xzxz );
}
void BBS_hash_3D( vec3 gridcell, out vec4 lowz_hash, out vec4 highz_hash )		//	generates a random number for each of the 8 cell corners
{
	//	gridcell is assumed to be an integer coordinate

	//	was having precision issues here with 61.0.  60.0 fixes it.  need to test on other cards.
	const float DOMAIN = 60.0;
	gridcell.xyz = gridcell.xyz - floor(gridcell.xyz * ( 1.0 / DOMAIN )) * DOMAIN;
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, ( DOMAIN - 1.5 ).xxx ) );

	vec4 p = BBS_permute( vec2( gridcell.x, gridcell_inc1.x ).xyxy /* * 7.0 */ );  // * 7.0 will increase variance close to origin
	p = BBS_permute( p + vec2( gridcell.y, gridcell_inc1.y ).xxyy );
	lowz_hash = BBS_permute_and_resolve( p + gridcell.zzzz );
	highz_hash = BBS_permute_and_resolve( p + gridcell_inc1.zzzz );
}


//
//	FAST32_hash
//	A very fast hashing function.  Requires 32bit support.
//	http://briansharpe.wordpress.com/2011/11/15/a-fast-and-simple-32bit-floating-point-hash-function/
//
//	The hash formula takes the form....
//	hash = mod( coord.x * coord.x * coord.y * coord.y, SOMELARGEFLOAT ) / SOMELARGEFLOAT
//	We truncate and offset the domain to the most interesting part of the noise.
//	SOMELARGEFLOAT should be in the range of 400.0->1000.0 and needs to be hand picked.  Only some give good results.
//	3D Noise is achieved by offsetting the SOMELARGEFLOAT value by the Z coordinate
//
vec4 FAST32_hash_2D( vec2 gridcell )	//	generates a random number for each of the 4 cell corners
{
	//	gridcell is assumed to be an integer coordinate
	const vec2 OFFSET = vec2( 26.0, 161.0 );
	const float DOMAIN = 71.0;
	const float SOMELARGEFLOAT = 951.135664;
	vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0.xx );
	P = P - floor(P * ( 1.0 / DOMAIN )) * DOMAIN;	//	truncate the domain
	P += OFFSET.xyxy;								//	offset to interesting part of the noise
	P *= P;											//	calculate and return the hash
	return fract( P.xzxz * P.yyww * ( 1.0 / SOMELARGEFLOAT.x ).xxxx );
}
void FAST32_hash_2D( vec2 gridcell, out vec4 hash_0, out vec4 hash_1 )	//	generates 2 random numbers for each of the 4 cell corners
{
	//    gridcell is assumed to be an integer coordinate
	const vec2 OFFSET = vec2( 26.0, 161.0 );
	const float DOMAIN = 71.0;
	const vec2 SOMELARGEFLOATS = vec2( 951.135664, 642.949883 );
	vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0.xx );
	P = P - floor(P * ( 1.0 / DOMAIN )) * DOMAIN;
	P += OFFSET.xyxy;
	P *= P;
	P = P.xzxz * P.yyww;
	hash_0 = fract( P * ( 1.0 / SOMELARGEFLOATS.x ).xxxx );
	hash_1 = fract( P * ( 1.0 / SOMELARGEFLOATS.y ).xxxx );
}
void FAST32_hash_2D( 	vec2 gridcell,
						out vec4 hash_0,
						out vec4 hash_1,
						out vec4 hash_2	)	//	generates 3 random numbers for each of the 4 cell corners
{
	//    gridcell is assumed to be an integer coordinate
	const vec2 OFFSET = vec2( 26.0, 161.0 );
	const float DOMAIN = 71.0;
	const vec3 SOMELARGEFLOATS = vec3( 951.135664, 642.949883, 803.202459 );
	vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0.xx );
	P = P - floor(P * ( 1.0 / DOMAIN )) * DOMAIN;
	P += OFFSET.xyxy;
	P *= P;
	P = P.xzxz * P.yyww;
	hash_0 = fract( P * ( 1.0 / SOMELARGEFLOATS.x ).xxxx );
	hash_1 = fract( P * ( 1.0 / SOMELARGEFLOATS.y ).xxxx );
	hash_2 = fract( P * ( 1.0 / SOMELARGEFLOATS.z ).xxxx );
}
vec4 FAST32_hash_2D_Cell( vec2 gridcell )	//	generates 4 different random numbers for the single given cell point
{
	//	gridcell is assumed to be an integer coordinate
	const vec2 OFFSET = vec2( 26.0, 161.0 );
	const float DOMAIN = 71.0;
	const vec4 SOMELARGEFLOATS = vec4( 951.135664, 642.949883, 803.202459, 986.973274 );
	vec2 P = gridcell - floor(gridcell * ( 1.0 / DOMAIN.xx )) * DOMAIN.xx;
	P += OFFSET.xy;
	P *= P;
	return fract( (P.x * P.y).xxxx * ( 1.0 / SOMELARGEFLOATS.xyzw ) );
}
void FAST32_hash_3D( vec3 gridcell, out vec4 lowz_hash, out vec4 highz_hash )	//	generates a random number for each of the 8 cell corners
{
	//    gridcell is assumed to be an integer coordinate

	//	TODO: 	these constants need tweaked to find the best possible noise.
	//			probably requires some kind of brute force computational searching or something....
	const vec2 OFFSET = vec2( 50.0, 161.0 );
	const float DOMAIN = 69.0;
	const float SOMELARGEFLOAT = 635.298681;
	const float ZINC = 48.500388;

	//	truncate the domain
	gridcell.xyz = gridcell.xyz - floor(gridcell.xyz * ( 1.0 / DOMAIN )) * DOMAIN;
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, ( DOMAIN - 1.5 ).xxx ) );

	//	calculate the noise
	vec4 P = vec4( gridcell.xy, gridcell_inc1.xy ) + OFFSET.xyxy;
	P *= P;
	P = P.xzxz * P.yyww;
	highz_hash.xy = vec2( 1.0.xx / ( SOMELARGEFLOAT.xx + vec2( gridcell.z, gridcell_inc1.z ) * ZINC.xx ) );
	lowz_hash = fract( P * highz_hash.xxxx );
	highz_hash = fract( P * highz_hash.yyyy );
}
void FAST32_hash_3D( 	vec3 gridcell,
						vec3 v1_mask,		//	user definable v1 and v2.  ( 0's and 1's )
						vec3 v2_mask,
						out vec4 hash_0,
						out vec4 hash_1,
						out vec4 hash_2	)		//	generates 3 random numbers for each of the 4 3D cell corners.  cell corners:  v0=0,0,0  v3=1,1,1  the other two are user definable
{
	//    gridcell is assumed to be an integer coordinate

	//	TODO: 	these constants need tweaked to find the best possible noise.
	//			probably requires some kind of brute force computational searching or something....
	const vec2 OFFSET = vec2( 50.0, 161.0 );
	const float DOMAIN = 69.0;
	const vec3 SOMELARGEFLOATS = vec3( 635.298681, 682.357502, 668.926525 );
	const vec3 ZINC = vec3( 48.500388, 65.294118, 63.934599 );

	//	truncate the domain
	gridcell.xyz = gridcell.xyz - floor(gridcell.xyz * ( 1.0 / DOMAIN )) * DOMAIN;
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, ( DOMAIN - 1.5 ).xxx ) );

	//	compute x*x*y*y for the 4 corners
	vec4 P = vec4( gridcell.xy, gridcell_inc1.xy ) + OFFSET.xyxy;
	P *= P;
	vec4 V1xy_V2xy = mix( P.zwzw, P.xyxy, lessThan( vec4( v1_mask.xy, v2_mask.xy ), 0.5.xxxx ) );		//	apply mask for v1 and v2
	P = vec4( P.x, V1xy_V2xy.xz, P.z ) * vec4( P.y, V1xy_V2xy.yw, P.w );

	//	get the lowz and highz mods
	vec3 lowz_mods = vec3( 1.0.xxx / ( SOMELARGEFLOATS.xyz + gridcell.zzz * ZINC.xyz ) );
	vec3 highz_mods = vec3( 1.0.xxx / ( SOMELARGEFLOATS.xyz + gridcell_inc1.zzz * ZINC.xyz ) );

	//	apply mask for v1 and v2 mod values
	v1_mask = mix( highz_mods, lowz_mods, lessThan( v1_mask.zzz, 0.5.xxx ) );
	v2_mask = mix( highz_mods, lowz_mods, lessThan( v2_mask.zzz, 0.5.xxx ) );

	//	compute the final hash
	hash_0 = fract( P * vec4( lowz_mods.x, v1_mask.x, v2_mask.x, highz_mods.x ) );
	hash_1 = fract( P * vec4( lowz_mods.y, v1_mask.y, v2_mask.y, highz_mods.y ) );
	hash_2 = fract( P * vec4( lowz_mods.z, v1_mask.z, v2_mask.z, highz_mods.z ) );
}
vec4 FAST32_hash_3D( 	vec3 gridcell,
						vec3 v1_mask,		//	user definable v1 and v2.  ( 0's and 1's )
						vec3 v2_mask )		//	generates 1 random number for each of the 4 3D cell corners.  cell corners:  v0=0,0,0  v3=1,1,1  the other two are user definable
{
	//    gridcell is assumed to be an integer coordinate

	//	TODO: 	these constants need tweaked to find the best possible noise.
	//			probably requires some kind of brute force computational searching or something....
	const vec2 OFFSET = vec2( 50.0, 161.0 );
	const float DOMAIN = 69.0;
	const float SOMELARGEFLOAT = 635.298681;
	const float ZINC = 48.500388;

	//	truncate the domain
	gridcell.xyz = gridcell.xyz - floor(gridcell.xyz * ( 1.0 / DOMAIN )) * DOMAIN;
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, ( DOMAIN - 1.5 ).xxx ) );

	//	compute x*x*y*y for the 4 corners
	vec4 P = vec4( gridcell.xy, gridcell_inc1.xy ) + OFFSET.xyxy;
	P *= P;
	vec4 V1xy_V2xy = mix( P.zwzw, P.xyxy, lessThan( vec4( v1_mask.xy, v2_mask.xy ), 0.5.xxxx ) );		//	apply mask for v1 and v2
	P = vec4( P.x, V1xy_V2xy.xz, P.z ) * vec4( P.y, V1xy_V2xy.yw, P.w );

	//	get the z mod vals
	vec2 V1z_V2z = mix( gridcell_inc1.zz, gridcell.zz, lessThan( vec2( v1_mask.z, v2_mask.z ), 0.5.xx ) );
	vec4 mod_vals = vec4( 1.0.xxxx / ( SOMELARGEFLOAT.xxxx + vec4( gridcell.z, V1z_V2z, gridcell_inc1.z ) * ZINC.xxxx ) );

	//	compute the final hash
	return fract( P * mod_vals );
}
void FAST32_hash_3D( 	vec3 gridcell,
						out vec4 lowz_hash_0,
						out vec4 lowz_hash_1,
						out vec4 lowz_hash_2,
						out vec4 highz_hash_0,
						out vec4 highz_hash_1,
						out vec4 highz_hash_2	)		//	generates 3 random numbers for each of the 8 cell corners
{
	//    gridcell is assumed to be an integer coordinate

	//	TODO: 	these constants need tweaked to find the best possible noise.
	//			probably requires some kind of brute force computational searching or something....
	const vec2 OFFSET = vec2( 50.0, 161.0 );
	const float DOMAIN = 69.0;
	const vec3 SOMELARGEFLOATS = vec3( 635.298681, 682.357502, 668.926525 );
	const vec3 ZINC = vec3( 48.500388, 65.294118, 63.934599 );

	//	truncate the domain
	gridcell.xyz = gridcell.xyz - floor(gridcell.xyz * ( 1.0 / DOMAIN )) * DOMAIN;
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, ( DOMAIN - 1.5 ).xxx ) );

	//	calculate the noise
	vec4 P = vec4( gridcell.xy, gridcell_inc1.xy ) + OFFSET.xyxy;
	P *= P;
	P = P.xzxz * P.yyww;
	lowz_hash_2.xyzw = vec4( 1.0.xxxx / ( SOMELARGEFLOATS.xyzx + vec2( gridcell.z, gridcell_inc1.z ).xxxy * ZINC.xyzx ) );
	highz_hash_2.xy = vec2( 1.0.xx / ( SOMELARGEFLOATS.yz + gridcell_inc1.zz * ZINC.yz ) );
	lowz_hash_0 = fract( P * lowz_hash_2.xxxx );
	highz_hash_0 = fract( P * lowz_hash_2.wwww );
	lowz_hash_1 = fract( P * lowz_hash_2.yyyy );
	highz_hash_1 = fract( P * highz_hash_2.xxxx );
	lowz_hash_2 = fract( P * lowz_hash_2.zzzz );
	highz_hash_2 = fract( P * highz_hash_2.yyyy );
}
void FAST32_hash_3D( 	vec3 gridcell,
						out vec4 lowz_hash_0,
						out vec4 lowz_hash_1,
						out vec4 lowz_hash_2,
						out vec4 lowz_hash_3,
						out vec4 highz_hash_0,
						out vec4 highz_hash_1,
						out vec4 highz_hash_2,
						out vec4 highz_hash_3	)		//	generates 4 random numbers for each of the 8 cell corners
{
	//    gridcell is assumed to be an integer coordinate

	//	TODO: 	these constants need tweaked to find the best possible noise.
	//			probably requires some kind of brute force computational searching or something....
	const vec2 OFFSET = vec2( 50.0, 161.0 );
	const float DOMAIN = 69.0;
	const vec4 SOMELARGEFLOATS = vec4( 635.298681, 682.357502, 668.926525, 588.255119 );
	const vec4 ZINC = vec4( 48.500388, 65.294118, 63.934599, 63.279683 );

	//	truncate the domain
	gridcell.xyz = gridcell.xyz - floor(gridcell.xyz * ( 1.0 / DOMAIN )) * DOMAIN;
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, ( DOMAIN - 1.5 ).xxx ) );

	//	calculate the noise
	vec4 P = vec4( gridcell.xy, gridcell_inc1.xy ) + OFFSET.xyxy;
	P *= P;
	P = P.xzxz * P.yyww;
	lowz_hash_3.xyzw = vec4( 1.0.xxxx / ( SOMELARGEFLOATS.xyzw + gridcell.zzzz * ZINC.xyzw ) );
	highz_hash_3.xyzw = vec4( 1.0.xxxx / ( SOMELARGEFLOATS.xyzw + gridcell_inc1.zzzz * ZINC.xyzw ) );
	lowz_hash_0 = fract( P * lowz_hash_3.xxxx );
	highz_hash_0 = fract( P * highz_hash_3.xxxx );
	lowz_hash_1 = fract( P * lowz_hash_3.yyyy );
	highz_hash_1 = fract( P * highz_hash_3.yyyy );
	lowz_hash_2 = fract( P * lowz_hash_3.zzzz );
	highz_hash_2 = fract( P * highz_hash_3.zzzz );
	lowz_hash_3 = fract( P * lowz_hash_3.wwww );
	highz_hash_3 = fract( P * highz_hash_3.wwww );
}


//
//	Interpolation functions
//	( smoothly increase from 0.0 to 1.0 as x increases linearly from 0.0 to 1.0 )
//	http://briansharpe.wordpress.com/2011/11/14/two-useful-interpolation-functions-for-noise-development/
//

//	Hermine Curve.  Same as SmoothStep().  As used by Perlin in Original Noise.
//	3x^2-2x^3
float Interpolation_C1( float x ) { return x * x * (3.0 - 2.0 * x); }
vec2 Interpolation_C1( vec2 x ) { return x * x * (3.0 - 2.0 * x); }
vec3 Interpolation_C1( vec3 x ) { return x * x * (3.0 - 2.0 * x); }
vec4 Interpolation_C1( vec4 x ) { return x * x * (3.0 - 2.0 * x); }

//	Quintic Curve.  As used by Perlin in Improved Noise.  http://mrl.nyu.edu/~perlin/paper445.pdf
//	6x^5-15x^4+10x^3
float Interpolation_C2( float x ) { return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }
vec2 Interpolation_C2( vec2 x ) { return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }
vec3 Interpolation_C2( vec3 x ) { return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }
vec4 Interpolation_C2( vec4 x ) { return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }

//	Faster than Perlin Quintic.  Not quite as good shape.
//	7x^3-7x^4+x^7
float Interpolation_C2_Fast( float x ) { float x3 = x*x*x; return ( 7.0 + ( x3 - 7.0 ) * x ) * x3; }
vec2 Interpolation_C2_Fast( vec2 x ) { vec2 x3 = x*x*x; return ( 7.0 + ( x3 - 7.0 ) * x ) * x3; }
vec3 Interpolation_C2_Fast( vec3 x ) { vec3 x3 = x*x*x; return ( 7.0 + ( x3 - 7.0 ) * x ) * x3; }
vec4 Interpolation_C2_Fast( vec4 x ) { vec4 x3 = x*x*x; return ( 7.0 + ( x3 - 7.0 ) * x ) * x3; }

//	C3 Interpolation function.  If anyone ever needs it... :)
//	25x^4-48x^5+25x^6-x^10
float Interpolation_C3( float x ) { float xsq = x*x; float xsqsq = xsq*xsq; return xsqsq * ( 25.0 - 48.0 * x + xsq * ( 25.0 - xsqsq ) ); }
vec2 Interpolation_C3( vec2 x ) { vec2 xsq = x*x; vec2 xsqsq = xsq*xsq; return xsqsq * ( 25.0 - 48.0 * x + xsq * ( 25.0 - xsqsq ) ); }
vec3 Interpolation_C3( vec3 x ) { vec3 xsq = x*x; vec3 xsqsq = xsq*xsq; return xsqsq * ( 25.0 - 48.0 * x + xsq * ( 25.0 - xsqsq ) ); }
vec4 Interpolation_C3( vec4 x ) { vec4 xsq = x*x; vec4 xsqsq = xsq*xsq; return xsqsq * ( 25.0 - 48.0 * x + xsq * ( 25.0 - xsqsq ) ); }


//
//	Falloff functions defined in XSquared
//	( smooth falloff from 1.0 to 0.0 as xsq ranges from 0.0 to 1.0.  Suitable for fading out from a point via dot product )
//	http://briansharpe.wordpress.com/2011/11/14/two-useful-interpolation-functions-for-noise-development/
//

//	C1 XSquared Falloff
//	Used by Humus for lighting falloff in Just Cause 2.
//  "Making it large, beautiful, fast and consistent – Lessons learned developing Just Cause 2 by Emil Persson", GPUPro 1
//	( 1.0 - x*x )^2
float Falloff_Xsq_C1( float xsq ) { xsq = 1.0 - xsq; return xsq*xsq; }
vec2 Falloff_Xsq_C1( vec2 xsq ) { xsq = 1.0 - xsq; return xsq*xsq; }
vec3 Falloff_Xsq_C1( vec3 xsq ) { xsq = 1.0 - xsq; return xsq*xsq; }
vec4 Falloff_Xsq_C1( vec4 xsq ) { xsq = 1.0 - xsq; return xsq*xsq; }

//	C2 XSquared Falloff
//	1.0 - ( 9x^4-16x^6+9x^8-x^12 )
float Falloff_Xsq_C2( float xsq ) { float xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 9.0 - 16.0 * xsq + xsqsq * ( 9.0 - xsqsq ) ); }
vec2 Falloff_Xsq_C2( vec2 xsq ) { vec2 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 9.0 - 16.0 * xsq + xsqsq * ( 9.0 - xsqsq ) ); }
vec3 Falloff_Xsq_C2( vec3 xsq ) { vec3 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 9.0 - 16.0 * xsq + xsqsq * ( 9.0 - xsqsq ) ); }
vec4 Falloff_Xsq_C2( vec4 xsq ) { vec4 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 9.0 - 16.0 * xsq + xsqsq * ( 9.0 - xsqsq ) ); }

//	Fast C2 XSquared falloff
//	1.0 - ( 5x^4-5x^6+x^10 )      NOTE: alternative could be this.  1.0 - ( 3x^4-3x^8+x^12 ).  Shape not quite as good but requires no extra registers
float Falloff_Xsq_C2_Fast( float xsq ) { float xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 5.0 + xsq * ( xsqsq - 5.0 ) ); }
vec2 Falloff_Xsq_C2_Fast( vec2 xsq ) { vec2 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 5.0 + xsq * ( xsqsq - 5.0 ) ); }
vec3 Falloff_Xsq_C2_Fast( vec3 xsq ) { vec3 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 5.0 + xsq * ( xsqsq - 5.0 ) ); }
vec4 Falloff_Xsq_C2_Fast( vec4 xsq ) { vec4 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 5.0 + xsq * ( xsqsq - 5.0 ) ); }

//	C3 XSquared falloff.  If anyone ever needs it... :)
//	1.0 - ( 10x^4-20x^6+15x^8-4x^10 )
float Falloff_Xsq_C3( float xsq ) {	return 1.0 - xsq * xsq * ( 10.0 + xsq * ( xsq * ( 15.0 - 4.0 * xsq ) - 20.0 ) ); }
vec2 Falloff_Xsq_C3( vec2 xsq ) {	return 1.0 - xsq * xsq * ( 10.0 + xsq * ( xsq * ( 15.0 - 4.0 * xsq ) - 20.0 ) ); }
vec3 Falloff_Xsq_C3( vec3 xsq ) {	return 1.0 - xsq * xsq * ( 10.0 + xsq * ( xsq * ( 15.0 - 4.0 * xsq ) - 20.0 ) ); }
vec4 Falloff_Xsq_C3( vec4 xsq ) {	return 1.0 - xsq * xsq * ( 10.0 + xsq * ( xsq * ( 15.0 - 4.0 * xsq ) - 20.0 ) ); }



//
//	Value Noise 2D
//	Return value range of 0.0->1.0
//	http://briansharpe.files.wordpress.com/2011/11/valuesample1.jpg
//
float Value2D( vec2 P )
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec2 Pf = P - Pi;

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash = FAST32_hash_2D( Pi );
	//vec4 hash = BBS_hash_2D( Pi );
	//vec4 hash = SGPP_hash_2D( Pi );
	//vec4 hash = BBS_hash_hq_2D( Pi );

	//	blend the results and return
	vec2 blend = Interpolation_C2( Pf );
	vec2 res0 = mix( hash.xy, hash.zw, blend.y );
	return mix( res0.x, res0.y, blend.x );
}

//
//	Value Noise 3D
//	Return value range of 0.0->1.0
//	http://briansharpe.files.wordpress.com/2011/11/valuesample1.jpg
//
float Value3D( vec3 P )
{
	//	establish our grid cell and unit position
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_lowz, hash_highz;
	FAST32_hash_3D( Pi, hash_lowz, hash_highz );
	//BBS_hash_3D( Pi, hash_lowz, hash_highz );
	//SGPP_hash_3D( Pi, hash_lowz, hash_highz );

	//	blend the results and return
	vec3 blend = Interpolation_C2( Pf );
	vec4 res0 = mix( hash_lowz, hash_highz, blend.z );
	vec2 res1 = mix( res0.xy, res0.zw, blend.y );
	return mix( res1.x, res1.y, blend.x );
}


//
//	Perlin Noise 2D  ( gradient noise )
//	Return value range of -1.0->1.0
//	http://briansharpe.files.wordpress.com/2011/11/perlinsample.jpg
//
float Perlin2D( vec2 P )
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec4 Pf_Pfmin1 = P.xyxy - vec4( Pi, Pi + 1.0.xx );

#if 0
	//
	//	classic noise looks much better than improved noise in 2D, and with an efficent hash function runs at about the same speed.
	//	requires 2 random numbers per point.
	//

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_x, hash_y;
	FAST32_hash_2D( Pi, hash_x, hash_y );
	//SGPP_hash_2D( Pi, hash_x, hash_y );

	//	calculate the gradient results
	vec4 grad_x = hash_x - 0.49999.xxxx;
	vec4 grad_y = hash_y - 0.49999.xxxx;
	vec4 grad_results = inversesqrt( grad_x * grad_x + grad_y * grad_y ) * ( grad_x * Pf_Pfmin1.xzxz + grad_y * Pf_Pfmin1.yyww );
	grad_results *= 1.4142135623730950488016887242097.xxxx;		//	(optionally) scale things to a strict -1.0->1.0 range    *= 1.0/sqrt(0.5)

#else
	//
	//	2D improved perlin noise.
	//	requires 1 random value per point.
	//	does not look as good as classic in 2D due to only 4x4 different possible cell types.  But can run a lot faster than classic perlin noise if the hash function is slow
	//

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash = FAST32_hash_2D( Pi );
	//vec4 hash = BBS_hash_2D( Pi );
	//vec4 hash = SGPP_hash_2D( Pi );
	//vec4 hash = BBS_hash_hq_2D( Pi );

	//
	//	evaulate the gradients
	//	choose between the 4 diagonal gradients.  ( slightly slower than choosing the axis gradients, but shows less grid artifacts )
	//	NOTE:  diagonals give us a nice strict -1.0->1.0 range without additional scaling
	//	[1.0,1.0] [-1.0,1.0] [1.0,-1.0] [-1.0,-1.0]
	//
	hash -= 0.5.xxxx;
	vec4 grad_results = Pf_Pfmin1.xzxz * sign( hash ) + Pf_Pfmin1.yyww * sign( abs( hash ) - 0.25.xxxx );

#endif

	//	blend the results and return
	vec2 blend = Interpolation_C2( Pf_Pfmin1.xy );
	vec2 res0 = mix( grad_results.xy, grad_results.zw, blend.y );
	return mix( res0.x, res0.y, blend.x );
}

//
//	Perlin Noise 3D  ( gradient noise )
//	Return value range of -1.0->1.0
//	http://briansharpe.files.wordpress.com/2011/11/perlinsample.jpg
//
float Perlin3D( vec3 P )
{
	//	establish our grid cell and unit position
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;
	vec3 Pf_min1 = Pf - 1.0;

#if 1
	//
	//	classic noise.
	//	requires 3 random values per point.  with an efficent hash function will run faster than improved noise
	//

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hashx0, hashy0, hashz0, hashx1, hashy1, hashz1;
	FAST32_hash_3D( Pi, hashx0, hashy0, hashz0, hashx1, hashy1, hashz1 );
	//SGPP_hash_3D( Pi, hashx0, hashy0, hashz0, hashx1, hashy1, hashz1 );

	//	calculate the gradients
	vec4 grad_x0 = hashx0 - 0.49999.xxxx;
	vec4 grad_y0 = hashy0 - 0.49999.xxxx;
	vec4 grad_z0 = hashz0 - 0.49999.xxxx;
	vec4 grad_x1 = hashx1 - 0.49999.xxxx;
	vec4 grad_y1 = hashy1 - 0.49999.xxxx;
	vec4 grad_z1 = hashz1 - 0.49999.xxxx;
	vec4 grad_results_0 = inversesqrt( grad_x0 * grad_x0 + grad_y0 * grad_y0 + grad_z0 * grad_z0 ) * ( vec2( Pf.x, Pf_min1.x ).xyxy * grad_x0 + vec2( Pf.y, Pf_min1.y ).xxyy * grad_y0 + Pf.zzzz * grad_z0 );
	vec4 grad_results_1 = inversesqrt( grad_x1 * grad_x1 + grad_y1 * grad_y1 + grad_z1 * grad_z1 ) * ( vec2( Pf.x, Pf_min1.x ).xyxy * grad_x1 + vec2( Pf.y, Pf_min1.y ).xxyy * grad_y1 + Pf_min1.zzzz * grad_z1 );

	//	blend the gradients and return
	vec3 blend = Interpolation_C2( Pf );
	vec4 res0 = mix( grad_results_0, grad_results_1, blend.z );
	vec2 res1 = mix( res0.xy, res0.zw, blend.y );
	float final = mix( res1.x, res1.y, blend.x );
	final *= 1.1547005383792515290182975610039;		//	(optionally) scale things to a strict -1.0->1.0 range    *= 1.0/sqrt(0.75)
	return final;
#else
	//
	//	improved noise.
	//	requires 1 random value per point.  Will run faster than classic noise if a slow hashing function is used
	//

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_lowz, hash_highz;
	FAST32_hash_3D( Pi, hash_lowz, hash_highz );
	//BBS_hash_3D( Pi, hash_lowz, hash_highz );
	//SGPP_hash_3D( Pi, hash_lowz, hash_highz );

#if 0
	//
	//	this will implement Ken Perlins "improved" classic noise using the 12 mid-edge gradient points.
	//	NOTE:  mid-edge gradients give us a nice strict -1.0->1.0 range without additional scaling
	//	[1,1,0] [-1,1,0] [1,-1,0] [-1,-1,0]
	//	[1,0,1] [-1,0,1] [1,0,-1] [-1,0,-1]
	//	[0,1,1] [0,-1,1] [0,1,-1] [0,-1,-1]
	//
	hash_lowz *= 3.0;
	vec4 grad_results_0_0 = mix( vec2( Pf.y, Pf_min1.y ).xxyy, vec2( Pf.x, Pf_min1.x ).xyxy, lessThan( hash_lowz, 2.0.xxxx ) );
	vec4 grad_results_0_1 = mix( Pf.zzzz, vec2( Pf.y, Pf_min1.y ).xxyy, lessThan( hash_lowz, 1.0.xxxx ) );
	hash_lowz = fract( hash_lowz ) - 0.5;
	vec4 grad_results_0 = grad_results_0_0 * sign( hash_lowz ) + grad_results_0_1 * sign( abs( hash_lowz ) - 0.25.xxxx );

	hash_highz *= 3.0;
	vec4 grad_results_1_0 = mix( vec2( Pf.y, Pf_min1.y ).xxyy, vec2( Pf.x, Pf_min1.x ).xyxy, lessThan( hash_highz, 2.0.xxxx ) );
	vec4 grad_results_1_1 = mix( Pf_min1.zzzz, vec2( Pf.y, Pf_min1.y ).xxyy, lessThan( hash_highz, 1.0.xxxx ) );
	hash_highz = fract( hash_highz ) - 0.5;
	vec4 grad_results_1 = grad_results_1_0 * sign( hash_highz ) + grad_results_1_1 * sign( abs( hash_highz ) - 0.25.xxxx );

	//	blend the gradients and return
	vec3 blend = Interpolation_C2( Pf );
	vec4 res0 = mix( grad_results_0, grad_results_1, blend.z );
	vec2 res1 = mix( res0.xy, res0.zw, blend.y );
	return mix( res1.x, res1.y, blend.x );
#else
	//
	//	"improved" noise using 8 corner gradients.  Faster than the 12 mid-edge point method.
	//	Ken mentions using diagonals like this can cause "clumping", but we'll live with that.
	//	[1,1,1]  [-1,1,1]  [1,-1,1]  [-1,-1,1]
	//	[1,1,-1] [-1,1,-1] [1,-1,-1] [-1,-1,-1]
	//
	hash_lowz -= 0.5.xxxx;
	vec4 grad_results_0_0 = vec2( Pf.x, Pf_min1.x ).xyxy * sign( hash_lowz );
	hash_lowz = abs( hash_lowz ) - 0.25.xxxx;
	vec4 grad_results_0_1 = vec2( Pf.y, Pf_min1.y ).xxyy * sign( hash_lowz );
	vec4 grad_results_0_2 = Pf.zzzz * sign( abs( hash_lowz ) - 0.125.xxxx );
	vec4 grad_results_0 = grad_results_0_0 + grad_results_0_1 + grad_results_0_2;

	hash_highz -= 0.5.xxxx;
	vec4 grad_results_1_0 = vec2( Pf.x, Pf_min1.x ).xyxy * sign( hash_highz );
	hash_highz = abs( hash_highz ) - 0.25.xxxx;
	vec4 grad_results_1_1 = vec2( Pf.y, Pf_min1.y ).xxyy * sign( hash_highz );
	vec4 grad_results_1_2 = Pf_min1.zzzz * sign( abs( hash_highz ) - 0.125.xxxx );
	vec4 grad_results_1 = grad_results_1_0 + grad_results_1_1 + grad_results_1_2;

	//	blend the gradients and return
	vec3 blend = Interpolation_C2( Pf );
	vec4 res0 = mix( grad_results_0, grad_results_1, blend.z );
	vec2 res1 = mix( res0.xy, res0.zw, blend.y );
	return mix( res1.x, res1.y, blend.x ) * (2.0 / 3.0);	//	(optionally) mult by (2.0/3.0) to scale to a strict -1.0->1.0 range
#endif

#endif

}

//
//	ValuePerlin Noise 2D	( value gradient noise )
//	A uniform blend between value and perlin noise
//	Return value range of -1.0->1.0
//	http://briansharpe.files.wordpress.com/2011/11/valueperlinsample.jpg
//
float ValuePerlin2D( vec2 P, float blend_val )
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec4 Pf_Pfmin1 = P.xyxy - vec4( Pi, Pi + 1.0.xx );

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_x, hash_y, hash_z;
	FAST32_hash_2D( Pi, hash_x, hash_y, hash_z );

	//	calculate the gradient results
	vec4 grad_x = hash_x - 0.49999.xxxx;
	vec4 grad_y = hash_y - 0.49999.xxxx;
	vec4 grad_results = inversesqrt( grad_x * grad_x + grad_y * grad_y ) * ( grad_x * Pf_Pfmin1.xzxz + grad_y * Pf_Pfmin1.yyww );
	grad_results *= 1.4142135623730950488016887242097.xxxx;		//	scale the perlin component to a -1.0->1.0 range    *= 1.0/sqrt(0.5)
	grad_results = mix( (hash_z * 2.0.xxxx - 1.0.xxxx), grad_results, blend_val );

	//	blend the results and return
	vec2 blend = Interpolation_C2( Pf_Pfmin1.xy );
	vec2 res0 = mix( grad_results.xy, grad_results.zw, blend.y );
	return mix( res0.x, res0.y, blend.x );
}


//
//	ValuePerlin Noise 3D	( value gradient noise )
//	A uniform blend between value and perlin noise
//	Return value range of -1.0->1.0
//	http://briansharpe.files.wordpress.com/2011/11/valueperlinsample.jpg
//
float ValuePerlin3D( vec3 P, float blend_val )
{
	//	establish our grid cell and unit position
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;
	vec3 Pf_min1 = Pf - 1.0;

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hashx0, hashy0, hashz0, hashw0, hashx1, hashy1, hashz1, hashw1;
	FAST32_hash_3D( Pi, hashx0, hashy0, hashz0, hashw0, hashx1, hashy1, hashz1, hashw1 );

	//	calculate the gradients
	vec4 grad_x0 = hashx0 - 0.49999.xxxx;
	vec4 grad_y0 = hashy0 - 0.49999.xxxx;
	vec4 grad_z0 = hashz0 - 0.49999.xxxx;
	vec4 grad_x1 = hashx1 - 0.49999.xxxx;
	vec4 grad_y1 = hashy1 - 0.49999.xxxx;
	vec4 grad_z1 = hashz1 - 0.49999.xxxx;
	vec4 grad_results_0 = inversesqrt( grad_x0 * grad_x0 + grad_y0 * grad_y0 + grad_z0 * grad_z0 ) * ( vec2( Pf.x, Pf_min1.x ).xyxy * grad_x0 + vec2( Pf.y, Pf_min1.y ).xxyy * grad_y0 + Pf.zzzz * grad_z0 );
	vec4 grad_results_1 = inversesqrt( grad_x1 * grad_x1 + grad_y1 * grad_y1 + grad_z1 * grad_z1 ) * ( vec2( Pf.x, Pf_min1.x ).xyxy * grad_x1 + vec2( Pf.y, Pf_min1.y ).xxyy * grad_y1 + Pf_min1.zzzz * grad_z1 );
	grad_results_0 *= 1.1547005383792515290182975610039.xxxx;		//	scale the perlin component to a -1.0->1.0 range    *= 1.0/sqrt(0.75)
	grad_results_1 *= 1.1547005383792515290182975610039.xxxx;
	grad_results_0 = mix( (hashw0 * 2.0.xxxx - 1.0.xxxx), grad_results_0, blend_val );
	grad_results_1 = mix( (hashw1 * 2.0.xxxx - 1.0.xxxx), grad_results_1, blend_val );

	//	blend the gradients and return
	vec3 blend = Interpolation_C2( Pf );
	vec4 res0 = mix( grad_results_0, grad_results_1, blend.z );
	vec2 res1 = mix( res0.xy, res0.zw, blend.y );
	return mix( res1.x, res1.y, blend.x );
}


//
//	Cubist Noise 2D
//	http://briansharpe.files.wordpress.com/2011/12/cubistsample.jpg
//
//	Generates a noise which resembles a cubist-style painting pattern.  Final Range 0.0->1.0
//	NOTE:  contains discontinuities.  best used only for texturing.
//	NOTE:  Any serious game implementation should hard-code these parameter values for efficiency.
//
float Cubist2D( vec2 P, vec2 range_clamp )	// range_clamp.x = low, range_clamp.y = 1.0/(high-low).  suggest value low=-2.0  high=1.0
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec4 Pf_Pfmin1 = P.xyxy - vec4( Pi, Pi + 1.0.xx );

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_x, hash_y, hash_z;
	FAST32_hash_2D( Pi, hash_x, hash_y, hash_z );

	//	calculate the gradient results
	vec4 grad_x = hash_x - 0.49999.xxxx;
	vec4 grad_y = hash_y - 0.49999.xxxx;
	vec4 grad_results = inversesqrt( grad_x * grad_x + grad_y * grad_y ) * ( grad_x * Pf_Pfmin1.xzxz + grad_y * Pf_Pfmin1.yyww );

	//	invert the gradient to convert from perlin to cubist
	grad_results = ( hash_z - 0.5.xxxx ) * ( 1.0.xxxx / grad_results );

	//	blend the results and return
	vec2 blend = Interpolation_C2( Pf_Pfmin1.xy );
	vec2 res0 = mix( grad_results.xy, grad_results.zw, blend.y );
	float final = mix( res0.x, res0.y, blend.x );

	//	the 1.0/grad calculation pushes the result to a possible to +-infinity.  Need to clamp to keep things sane
	return clamp( ( final - range_clamp.x ) * range_clamp.y, 0.0, 1.0 );
	//return smoothstep( 0.0, 1.0, ( final - range_clamp.x ) * range_clamp.y );		//	experiments.  smoothstep doesn't look as good, but does remove some discontinuities....
}


//
//	Cubist Noise 3D
//	http://briansharpe.files.wordpress.com/2011/12/cubistsample.jpg
//
//	Generates a noise which resembles a cubist-style painting pattern.  Final Range 0.0->1.0
//	NOTE:  contains discontinuities.  best used only for texturing.
//	NOTE:  Any serious game implementation should hard-code these parameter values for efficiency.
//
float Cubist3D( vec3 P, vec2 range_clamp )	// range_clamp.x = low, range_clamp.y = 1.0/(high-low).  suggest value low=-2.0  high=1.0
{
	//	establish our grid cell and unit position
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;
	vec3 Pf_min1 = Pf - 1.0;

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hashx0, hashy0, hashz0, hashw0, hashx1, hashy1, hashz1, hashw1;
	FAST32_hash_3D( Pi, hashx0, hashy0, hashz0, hashw0, hashx1, hashy1, hashz1, hashw1 );

	//	calculate the gradients
	vec4 grad_x0 = hashx0 - 0.49999.xxxx;
	vec4 grad_y0 = hashy0 - 0.49999.xxxx;
	vec4 grad_z0 = hashz0 - 0.49999.xxxx;
	vec4 grad_x1 = hashx1 - 0.49999.xxxx;
	vec4 grad_y1 = hashy1 - 0.49999.xxxx;
	vec4 grad_z1 = hashz1 - 0.49999.xxxx;
	vec4 grad_results_0 = inversesqrt( grad_x0 * grad_x0 + grad_y0 * grad_y0 + grad_z0 * grad_z0 ) * ( vec2( Pf.x, Pf_min1.x ).xyxy * grad_x0 + vec2( Pf.y, Pf_min1.y ).xxyy * grad_y0 + Pf.zzzz * grad_z0 );
	vec4 grad_results_1 = inversesqrt( grad_x1 * grad_x1 + grad_y1 * grad_y1 + grad_z1 * grad_z1 ) * ( vec2( Pf.x, Pf_min1.x ).xyxy * grad_x1 + vec2( Pf.y, Pf_min1.y ).xxyy * grad_y1 + Pf_min1.zzzz * grad_z1 );

	//	invert the gradient to convert from perlin to cubist
	grad_results_0 = ( hashw0 - 0.5.xxxx ) * ( 1.0.xxxx / grad_results_0 );
	grad_results_1 = ( hashw1 - 0.5.xxxx ) * ( 1.0.xxxx / grad_results_1 );

	//	blend the gradients and return
	vec3 blend = Interpolation_C2( Pf );
	vec4 res0 = mix( grad_results_0, grad_results_1, blend.z );
	vec2 res1 = mix( res0.xy, res0.zw, blend.y );
	float final = mix( res1.x, res1.y, blend.x );

	//	the 1.0/grad calculation pushes the result to a possible to +-infinity.  Need to clamp to keep things sane
	return clamp( ( final - range_clamp.x ) * range_clamp.y, 0.0, 1.0 );
	//return smoothstep( 0.0, 1.0, ( final - range_clamp.x ) * range_clamp.y );		//	experiments.  smoothstep doesn't look as good, but does remove some discontinuities....
}


//	convert a 0.0->1.0 sample to a -1.0->1.0 sample weighted towards the extremes
vec4 Cellular_weight_samples( vec4 samples )
{
	samples = samples * 2.0 - 1.0;
	//return (1.0 - samples * samples) * sign(samples);	// square
	return (samples * samples * samples) - sign(samples);	// cubic (even more variance)
}

//
//	Cellular Noise 2D
//	Based off Stefan Gustavson's work at http://www.itn.liu.se/~stegu/GLSL-cellular
//	http://briansharpe.files.wordpress.com/2011/12/cellularsample.jpg
//
//	Speed up by using 2x2 search window instead of 3x3
//	produces range of 0.0->~1.0 ( max theoritical value of sqrt( 0.75^2 * 2.0 ) ~= 1.0607 for dist and ( 0.75^2 * 2.0 ) = 1.125 for dist sq, but should rarely reach that )
//
float Cellular2D(vec2 P)
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec2 Pf = P - Pi;

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_x, hash_y;
	FAST32_hash_2D( Pi, hash_x, hash_y );
	//SGPP_hash_2D( Pi, hash_x, hash_y );

	//	generate the 4 random points
#if 1
	//	restrict the random point offset to eliminate artifacts
	//	we'll improve the variance of the noise by pushing the points to the extremes of the jitter window
	const float JITTER_WINDOW = 0.25;	// 0.25 will guarentee no artifacts.  0.25 is the intersection on x of graphs f(x)=( (0.5+(0.5-x))^2 + (0.5-x)^2 ) and f(x)=( (0.5+x)^2 + x^2 )
	hash_x = Cellular_weight_samples( hash_x ) * JITTER_WINDOW + vec4(0.0, 1.0, 0.0, 1.0);
	hash_y = Cellular_weight_samples( hash_y ) * JITTER_WINDOW + vec4(0.0, 0.0, 1.0, 1.0);
#else
	//	non-weighted jitter window.  jitter window of 0.4 will give results similar to Stefans original implementation
	//	nicer looking, faster, but has minor artifacts.  ( discontinuities in signal )
	const float JITTER_WINDOW = 0.4;
	hash_x = hash_x * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, 1.0-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW);
	hash_y = hash_y * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW);
#endif

	//	return the closest squared distance
	vec4 dx = Pf.xxxx - hash_x;
	vec4 dy = Pf.yyyy - hash_y;
	vec4 d = dx * dx + dy * dy;
	d.xy = min(d.xy, d.zw);
	return min(d.x, d.y);
}


//
//	Cellular Noise 3D
//	Based off Stefan Gustavson's work at http://www.itn.liu.se/~stegu/GLSL-cellular
//	http://briansharpe.files.wordpress.com/2011/12/cellularsample.jpg
//
//	Speed up by using 2x2x2 search window instead of 3x3x3
//	produces range of 0.0->~1.0  ( max theoritical value of sqrt( 0.666666^2 * 3.0 ) ~= 1.155 for dist and ( 0.666666^2 * 3.0 ) ~= 1.33333 for dist sq, but should rarely reach that )
//
float Cellular3D(vec3 P)
{
	//	establish our grid cell and unit position
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_x0, hash_y0, hash_z0, hash_x1, hash_y1, hash_z1;
	FAST32_hash_3D( Pi, hash_x0, hash_y0, hash_z0, hash_x1, hash_y1, hash_z1 );
	//SGPP_hash_3D( Pi, hash_x0, hash_y0, hash_z0, hash_x1, hash_y1, hash_z1 );

	//	generate the 8 random points
#if 1
	//	restrict the random point offset to eliminate artifacts
	//	we'll improve the variance of the noise by pushing the points to the extremes of the jitter window
	const float JITTER_WINDOW = 0.166666666;	// 0.166666666 will guarentee no artifacts. It is the intersection on x of graphs f(x)=( (0.5 + (0.5-x))^2 + 2*((0.5-x)^2) ) and f(x)=( 2 * (( 0.5 + x )^2) + x * x )
	hash_x0 = Cellular_weight_samples( hash_x0 ) * JITTER_WINDOW + vec4(0.0, 1.0, 0.0, 1.0);
	hash_y0 = Cellular_weight_samples( hash_y0 ) * JITTER_WINDOW + vec4(0.0, 0.0, 1.0, 1.0);
	hash_x1 = Cellular_weight_samples( hash_x1 ) * JITTER_WINDOW + vec4(0.0, 1.0, 0.0, 1.0);
	hash_y1 = Cellular_weight_samples( hash_y1 ) * JITTER_WINDOW + vec4(0.0, 0.0, 1.0, 1.0);
	hash_z0 = Cellular_weight_samples( hash_z0 ) * JITTER_WINDOW + vec4(0.0, 0.0, 0.0, 0.0);
	hash_z1 = Cellular_weight_samples( hash_z1 ) * JITTER_WINDOW + vec4(1.0, 1.0, 1.0, 1.0);
#else
	//	non-weighted jitter window.  jitter window of 0.4 will give results similar to Stefans original implementation
	//	nicer looking, faster, but has minor artifacts.  ( discontinuities in signal )
	const float JITTER_WINDOW = 0.4;
	hash_x0 = hash_x0 * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, 1.0-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW);
	hash_y0 = hash_y0 * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW);
	hash_x1 = hash_x1 * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, 1.0-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW);
	hash_y1 = hash_y1 * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW);
	hash_z0 = hash_z0 * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, -JITTER_WINDOW, -JITTER_WINDOW, -JITTER_WINDOW);
	hash_z1 = hash_z1 * JITTER_WINDOW * 2.0 + vec4(1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW);
#endif

	//	return the closest squared distance
	vec4 dx1 = Pf.xxxx - hash_x0;
	vec4 dy1 = Pf.yyyy - hash_y0;
	vec4 dz1 = Pf.zzzz - hash_z0;
	vec4 dx2 = Pf.xxxx - hash_x1;
	vec4 dy2 = Pf.yyyy - hash_y1;
	vec4 dz2 = Pf.zzzz - hash_z1;
	vec4 d1 = dx1 * dx1 + dy1 * dy1 + dz1 * dz1;
	vec4 d2 = dx2 * dx2 + dy2 * dy2 + dz2 * dz2;
	d1 = min(d1, d2);
	d1.xy = min(d1.xy, d1.wz);
	return min(d1.x, d1.y);
}

//
//	PolkaDot Noise 2D
//	http://briansharpe.files.wordpress.com/2011/12/polkadotsample.jpg
//
//	Generates a noise of smooth falloff polka dots.
//	Allow for control on value and radius
//	Return value range of 0.0 -> ValRange.x+ValRange.y
//	NOTE:  Any serious game implementation should hard-code these parameter values for efficiency.
//
float PolkaDot2D( 	vec2 P,
					vec2 RadRange,		//	RadRange.x = low  RadRange.y = high-low  shader accepts 2.0/radius, so this should generate a range of 2.0->LARGENUM   ( 2.0 is a large dot, LARGENUM is a small dot eg 20.0 )
					vec2 ValRange	)	//	ValRange.x = low  ValRange.y = high-low  should generate a range between 0.0->1.0
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec2 Pf = P - Pi;

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash = FAST32_hash_2D_Cell( Pi );
	//vec4 hash = FAST32_hash_2D( Pi * 2.0 );		//	Need to multiply by 2.0 here because we want to use all 4 corners once per cell.  No sharing with other cells.  It helps if the hash function has an odd domain.
	//vec4 hash = BBS_hash_2D( Pi * 2.0 );
	//vec4 hash = SGPP_hash_2D( Pi * 2.0 );
	//vec4 hash = BBS_hash_hq_2D( Pi * 2.0 );

	//	user variables
	float RADIUS = hash.z * RadRange.y + RadRange.x;		//	NOTE: we can parallelize this.  ( but seems like the compiler does it automatically anyway? )
	float VALUE = hash.w * ValRange.y + ValRange.x;

	//	calc the noise and return
	Pf *= RADIUS.xx;
	Pf -= ( RADIUS.xx - 1.0.xx );
	Pf += hash.xy * ( RADIUS.xx - 2.0.xx );
	return Falloff_Xsq_C2_Fast( min( dot( Pf, Pf ), 1.0 ) ) * VALUE;
}
//	PolkaDot2D_FixedRadius, PolkaDot2D_FixedValue, PolkaDot2D_FixedRadius_FixedValue TODO

//
//	PolkaDot Noise 3D
//	http://briansharpe.files.wordpress.com/2011/12/polkadotsample.jpg
//
//	Generates a noise of smooth falloff polka dots.
//	Allow for control on value and radius
//	Return value range of 0.0 -> ValRange.x+ValRange.y
//	NOTE:  Any serious game implementation should hard-code these parameter values for efficiency.
//
float PolkaDot3D( 	vec3 P,
					vec2 RadRange,		//	RadRange.x = low  RadRange.y = high-low  shader accepts 2.0/radius, so this should generate a range of 2.0->LARGENUM   ( 2.0 is a large dot, LARGENUM is a small dot eg 20.0 )
					vec2 ValRange	)	//	ValRange.x = low  ValRange.y = high-low  should generate a range between 0.0->1.0
{
	//	establish our grid cell and unit position
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_lowz, hash_highz;
	FAST32_hash_3D( Pi * 2.0, hash_lowz, hash_highz );	//	Need to multiply by 2.0 here because we want to use all 8 corners once per cell.  No sharing with other cells.  It helps if the hash function has an odd domain.
	//BBS_hash_3D( Pi * 2.0, hash_lowz, hash_highz );
	//SGPP_hash_3D( Pi * 2.0, hash_lowz, hash_highz );

	//	user variables
	float RADIUS = hash_lowz.w * RadRange.y + RadRange.x;		//	NOTE: we can parallelize this.  ( but seems like the compiler does it automatically anyway? )
	float VALUE = hash_highz.x * ValRange.y + ValRange.x;

	//	calc the noise and return
	Pf *= RADIUS.xxx;
	Pf -= ( RADIUS.xxx - 1.0.xxx );
	Pf += hash_lowz.xyz * ( RADIUS.xxx - 2.0.xxx );
	return Falloff_Xsq_C2_Fast( min( dot( Pf, Pf ), 1.0 ) ) * VALUE;
}
//	PolkaDot3D_FixedRadius, PolkaDot3D_FixedValue, PolkaDot3D_FixedRadius_FixedValue TODO

//
//	Stars2D
//	http://briansharpe.files.wordpress.com/2011/12/starssample.jpg
//
//	procedural texture for creating a starry background.  ( looks good when combined with a nebula/space-like colour texture )
//	NOTE:  Any serious game implementation should hard-code these parameter values for efficiency.
//
float Stars2D(	vec2 P,
				float probability_threshold,		//	probability a star will be drawn  ( 0.0->1.0 )
				float max_dimness,					//	the maximal dimness of a star ( 0.0->1.0   0.0 = all stars bright,  1.0 = maximum variation )
				float two_over_radius )				//	fixed radius for the stars.  radius range is 0.0->1.0.  shader requires 2.0/radius as input.
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec2 Pf = P - Pi;

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash = FAST32_hash_2D_Cell( Pi );
	//vec4 hash = FAST32_hash_2D( Pi * 2.0 );		//	Need to multiply by 2.0 here because we want to use all 4 corners once per cell.  No sharing with other cells.  It helps if the hash function has an odd domain.
	//vec4 hash = BBS_hash_2D( Pi * 2.0 );
	//vec4 hash = SGPP_hash_2D( Pi * 2.0 );
	//vec4 hash = BBS_hash_hq_2D( Pi * 2.0 );

	//	user variables
	float VALUE = 1.0 - max_dimness * hash.z;

	//	calc the noise and return
	Pf *= two_over_radius.xx;
	Pf -= ( two_over_radius.xx - 1.0.xx );
	Pf += hash.xy * ( two_over_radius.xx - 2.0.xx );
	return ( hash.w < probability_threshold ) ? ( Falloff_Xsq_C1( min( dot( Pf, Pf ), 1.0 ) ) * VALUE ) : 0.0;		//	C1 here suggests that this only be used for texturing and not for displacement
}


//
//	SimplexValue2D
//	value noise over a simplex (triangular) grid
//	Return value range of 0.0->1.0
//
float SimplexValue2D( vec2 P )
{
	//	simplex math based off Stefan Gustavson's and Ian McEwan's work at...
	//	http://github.com/ashima/webgl-noise

	//	simplex math constants
	const float SKEWFACTOR = 0.36602540378443864676372317075294;			// 0.5*(sqrt(3.0)-1.0)
	const float UNSKEWFACTOR = 0.21132486540518711774542560974902;			// (3.0-sqrt(3.0))/6.0
	const float SIMPLEX_TRI_HEIGHT = 0.70710678118654752440084436210485;	// sqrt( 0.5 )	height of simplex triangle
	const vec3 SIMPLEX_POINTS = vec3( 1.0-UNSKEWFACTOR, -UNSKEWFACTOR, 1.0-2.0*UNSKEWFACTOR );		//	vertex info for simplex triangle

	//	establish our grid cell.
	P *= SIMPLEX_TRI_HEIGHT;		// scale space so we can have an approx feature size of 1.0  ( optional )
	vec2 Pi = floor( P + dot( P, SKEWFACTOR.xx ).xx );

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash = FAST32_hash_2D( Pi );
	//vec4 hash = BBS_hash_2D( Pi );
	//vec4 hash = SGPP_hash_2D( Pi );
	//vec4 hash = BBS_hash_hq_2D( Pi );

	//	establish vectors to the 3 corners of our simplex triangle
	vec2 v0 = Pi - dot( Pi, UNSKEWFACTOR.xx ).xx - P;
	vec3 v1pos_v1hash = (v0.x < v0.y) ? vec3(SIMPLEX_POINTS.xy, hash.y) : vec3(SIMPLEX_POINTS.yx, hash.z);
	vec4 v12 = vec4( v1pos_v1hash.xy, SIMPLEX_POINTS.zz ) + v0.xyxy;
	vec3 v012_vals = vec3( hash.x, v1pos_v1hash.z, hash.w );

	//	evaluate the surflet, sum and return
	vec3 m = vec3( v0.x, v12.xz ) * vec3( v0.x, v12.xz ) + vec3( v0.y, v12.yw ) * vec3( v0.y, v12.yw );
	m = max(0.5.xxx - m, 0.0.xxx);		//	The 0.5 here is SIMPLEX_TRI_HEIGHT^2
	m = m*m;
	m = m*m;
	return dot(m, v012_vals) * 16.0;  //	16 = 1.0 / ( 0.5^4 )
}

//
//	SimplexPerlin2D  ( simplex gradient noise )
//	Perlin noise over a simplex (triangular) grid
//	Return value range of -1.0->1.0
//
//	Implementation originally based off Stefan Gustavson's and Ian McEwan's work at...
//	http://github.com/ashima/webgl-noise
//
float SimplexPerlin2D( vec2 P )
{
	//	simplex math constants
	const float SKEWFACTOR = 0.36602540378443864676372317075294;			// 0.5*(sqrt(3.0)-1.0)
	const float UNSKEWFACTOR = 0.21132486540518711774542560974902;			// (3.0-sqrt(3.0))/6.0
	const float SIMPLEX_TRI_HEIGHT = 0.70710678118654752440084436210485;	// sqrt( 0.5 )	height of simplex triangle
	const vec3 SIMPLEX_POINTS = vec3( 1.0-UNSKEWFACTOR, -UNSKEWFACTOR, 1.0-2.0*UNSKEWFACTOR );		//	vertex info for simplex triangle

	//	establish our grid cell.
	P *= SIMPLEX_TRI_HEIGHT;		// scale space so we can have an approx feature size of 1.0  ( optional )
	vec2 Pi = floor( P + dot( P, SKEWFACTOR.xx ).xx );

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_x, hash_y;
	FAST32_hash_2D( Pi, hash_x, hash_y );
	//SGPP_hash_2D( Pi, hash_x, hash_y );

	//	establish vectors to the 3 corners of our simplex triangle
	vec2 v0 = Pi - dot( Pi, UNSKEWFACTOR.xx ).xx - P;
	vec4 v1pos_v1hash = (v0.x < v0.y) ? vec4(SIMPLEX_POINTS.xy, hash_x.y, hash_y.y) : vec4(SIMPLEX_POINTS.yx, hash_x.z, hash_y.z);
	vec4 v12 = vec4( v1pos_v1hash.xy, SIMPLEX_POINTS.zz ) + v0.xyxy;

	//	calculate the dotproduct of our 3 corner vectors with 3 random normalized vectors
	vec3 grad_x = vec3( hash_x.x, v1pos_v1hash.z, hash_x.w ) - 0.49999.xxx;
	vec3 grad_y = vec3( hash_y.x, v1pos_v1hash.w, hash_y.w ) - 0.49999.xxx;
	vec3 grad_results = inversesqrt( grad_x * grad_x + grad_y * grad_y ) * ( grad_x * vec3( v0.x, v12.xz ) + grad_y * vec3( v0.y, v12.yw ) );

	const float FINAL_NORMALIZATION = 99.204310604478759765467803137703;	//	scales the final result to a strict 1.0->-1.0 range

	//	evaluate the surflet, sum and return
	vec3 m = vec3( v0.x, v12.xz ) * vec3( v0.x, v12.xz ) + vec3( v0.y, v12.yw ) * vec3( v0.y, v12.yw );
	m = max(0.5.xxx - m, 0.0.xxx);		//	The 0.5 here is SIMPLEX_TRI_HEIGHT^2
	m = m*m;
	m = m*m;
	return dot(m, grad_results) * FINAL_NORMALIZATION;
}


//
//	SimplexCellular2D
//	cellular noise over a simplex (triangular) grid
//	Return value range of 0.0->~1.0
//
float SimplexCellular2D( vec2 P )
{
	//	simplex math based off Stefan Gustavson's and Ian McEwan's work at...
	//	http://github.com/ashima/webgl-noise

	//	simplex math constants
	const float SKEWFACTOR = 0.36602540378443864676372317075294;			// 0.5*(sqrt(3.0)-1.0)
	const float UNSKEWFACTOR = 0.21132486540518711774542560974902;			// (3.0-sqrt(3.0))/6.0
	const float SIMPLEX_TRI_HEIGHT = 0.70710678118654752440084436210485;	// sqrt( 0.5 )	height of simplex triangle.
	const float INV_SIMPLEX_TRI_HEIGHT = 1.4142135623730950488016887242097;	//	1.0 / sqrt( 0.5 )
	const vec3 SIMPLEX_POINTS = vec3( 1.0-UNSKEWFACTOR, -UNSKEWFACTOR, 1.0-2.0*UNSKEWFACTOR ) * INV_SIMPLEX_TRI_HEIGHT.xxx;		//	vertex info for simplex triangle

	//	establish our grid cell.
	P *= SIMPLEX_TRI_HEIGHT;		// scale space so we can have an approx feature size of 1.0  ( optional )
	vec2 Pi = floor( P + dot( P, SKEWFACTOR.xx ).xx );

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_x, hash_y;
	FAST32_hash_2D( Pi, hash_x, hash_y );
	//SGPP_hash_2D( Pi, hash_x, hash_y );

	//	push hash values to extremes of jitter window
	const float JITTER_WINDOW = 0.14942924536134225401731517482694;		// this will guarentee no artifacts.   ( SIMPLEX_TRI_HEIGHT - ( SIMPLEX_TRI_EDGE_LEN / 2.0 ) ) / 2.0
	hash_x = Cellular_weight_samples( hash_x ) * JITTER_WINDOW;
	hash_y = Cellular_weight_samples( hash_y ) * JITTER_WINDOW;

	//	calculate sq distance to closest point
	vec2 p0 = ( ( Pi - dot( Pi, UNSKEWFACTOR.xx ).xx ) - P ) * INV_SIMPLEX_TRI_HEIGHT.xx;
	hash_x += p0.xxxx;
	hash_y += p0.yyyy;
	hash_x.yzw += SIMPLEX_POINTS.xyz;
	hash_y.yzw += SIMPLEX_POINTS.yxz;
	vec3 p_x = vec3( hash_x.x, (p0.x < p0.y) ? hash_x.y : hash_x.z, hash_x.w );
	vec3 p_y = vec3( hash_y.x, (p0.x < p0.y) ? hash_y.y : hash_y.z, hash_y.w );
	vec3 distsq = p_x*p_x + p_y*p_y;
	return min( distsq.x, min( distsq.y, distsq.z ) );
}

//
//	Given an arbitrary 3D point this calculates the 4 vectors from the corners of the simplex pyramid to the point
//	It also returns the integer grid index information for the corners
//
void Simplex3D_GetCornerVectors( 	vec3 P,					//	input point
									out vec3 Pi,			//	integer grid index for the origin
									out vec3 Pi_1,			//	offsets for the 2nd and 3rd corners.  ( the 4th = Pi + 1.0.xxx )
									out vec3 Pi_2,
									out vec4 v1234_x,		//	vectors from the 4 corners to the intput point
									out vec4 v1234_y,
									out vec4 v1234_z )
{
	//
	//	Simplex math from Stefan Gustavson's and Ian McEwan's work at...
	//	http://github.com/ashima/webgl-noise
	//

	//	simplex math constants
	const float SKEWFACTOR = 1.0/3.0;
	const float UNSKEWFACTOR = 1.0/6.0;
	const float SIMPLEX_CORNER_POS = 0.5;
	const float SIMPLEX_PYRAMID_HEIGHT = 0.70710678118654752440084436210485;	// sqrt( 0.5 )	height of simplex pyramid.

	P *= SIMPLEX_PYRAMID_HEIGHT;		// scale space so we can have an approx feature size of 1.0  ( optional )

	//	Find the vectors to the corners of our simplex pyramid
	Pi = floor( P + dot(P, SKEWFACTOR.xxx) );
	vec3 x0 = P - Pi + dot(Pi, UNSKEWFACTOR.xxx);
	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0.xxx - g;
	Pi_1 = min( g.xyz, l.zxy );
	Pi_2 = max( g.xyz, l.zxy );
	vec3 x1 = x0 - Pi_1 + UNSKEWFACTOR.xxx;
	vec3 x2 = x0 - Pi_2 + SKEWFACTOR.xxx;
	vec3 x3 = x0 - SIMPLEX_CORNER_POS.xxx;

	//	pack them into a parallel-friendly arrangement
	v1234_x = vec4( x0.x, x1.x, x2.x, x3.x );
	v1234_y = vec4( x0.y, x1.y, x2.y, x3.y );
	v1234_z = vec4( x0.z, x1.z, x2.z, x3.z );
}

//
//	Calculate the weights for the 3D simplex surflet
//
vec4 Simplex3D_GetSurfletWeights( 	vec4 v1234_x,
									vec4 v1234_y,
									vec4 v1234_z )
{
	//	perlins original implementation uses the surlet falloff formula of (0.6-x*x)^4.
	//	This is buggy as it can cause discontinuities along simplex faces.  (0.5-x*x)^3 solves this and gives an almost identical curve

	//	evaluate surflet. f(x)=(0.5-x*x)^3
	vec4 surflet_weights = v1234_x * v1234_x + v1234_y * v1234_y + v1234_z * v1234_z;
	surflet_weights = max(0.5.xxxx - surflet_weights, 0.0.xxxx);		//	0.5 here represents the closest distance (squared) of any simplex pyramid corner to any of its planes.  ie, SIMPLEX_PYRAMID_HEIGHT^2
	return surflet_weights*surflet_weights*surflet_weights;
}



//
//	SimplexPerlin3D  ( simplex gradient noise )
//	Perlin noise over a simplex (triangular) grid
//	Return value range of -1.0->1.0
//
//	Implementation originally based off Stefan Gustavson's and Ian McEwan's work at...
//	http://github.com/ashima/webgl-noise
//
float SimplexPerlin3D(vec3 P)
{
	//	calculate the simplex vector and index math
	vec3 Pi;
	vec3 Pi_1;
	vec3 Pi_2;
	vec4 v1234_x;
	vec4 v1234_y;
	vec4 v1234_z;
	Simplex3D_GetCornerVectors( P, Pi, Pi_1, Pi_2, v1234_x, v1234_y, v1234_z );

	//	generate the random vectors
	//	( various hashing methods listed in order of speed )
	vec4 hash_0;
	vec4 hash_1;
	vec4 hash_2;
	FAST32_hash_3D( Pi, Pi_1, Pi_2, hash_0, hash_1, hash_2 );
	//SGPP_hash_3D( Pi, Pi_1, Pi_2, hash_0, hash_1, hash_2 );
	hash_0 -= 0.49999.xxxx;
	hash_1 -= 0.49999.xxxx;
	hash_2 -= 0.49999.xxxx;

	//	evaluate gradients
	vec4 grad_results = inversesqrt( hash_0 * hash_0 + hash_1 * hash_1 + hash_2 * hash_2 ) * ( hash_0 * v1234_x + hash_1 * v1234_y + hash_2 * v1234_z );

	const float FINAL_NORMALIZATION = 37.837217149891986479046334729594;	//	scales the final result to a strict 1.0->-1.0 range

	//	sum with the surflet and return
	return dot( Simplex3D_GetSurfletWeights( v1234_x, v1234_y, v1234_z ), grad_results ) * FINAL_NORMALIZATION;
}

//
//	SimplexValue3D
//	Value noise over a simplex (triangular) grid
//	Return value range of 0.0->1.0
//
float SimplexValue3D(vec3 P)
{
	//	calculate the simplex vector and index math
	vec3 Pi;
	vec3 Pi_1;
	vec3 Pi_2;
	vec4 v1234_x;
	vec4 v1234_y;
	vec4 v1234_z;
	Simplex3D_GetCornerVectors( P, Pi, Pi_1, Pi_2, v1234_x, v1234_y, v1234_z );

	//	calculate the hash
	vec4 hash = FAST32_hash_3D( Pi, Pi_1, Pi_2 );

	//	sum with the surflet and return
	return dot( Simplex3D_GetSurfletWeights( v1234_x, v1234_y, v1234_z ), hash ) * 8.0;	  //	8 = 1.0 / ( 0.5^3 )
}

//
//	SimplexCellular3D
//	cellular noise over a simplex (triangular) grid
//	Return value range of 0.0->~1.0
//
float SimplexCellular3D( vec3 P )
{
	//	calculate the simplex vector and index math
	vec3 Pi;
	vec3 Pi_1;
	vec3 Pi_2;
	vec4 v1234_x;
	vec4 v1234_y;
	vec4 v1234_z;
	Simplex3D_GetCornerVectors( P, Pi, Pi_1, Pi_2, v1234_x, v1234_y, v1234_z );

	//	generate the random vectors
	//	( various hashing methods listed in order of speed )
	vec4 hash_x;
	vec4 hash_y;
	vec4 hash_z;
	FAST32_hash_3D( Pi, Pi_1, Pi_2, hash_x, hash_y, hash_z );
	//SGPP_hash_3D( Pi, Pi_1, Pi_2, hash_x, hash_y, hash_z );

	//	push hash values to extremes of jitter window
	const float JITTER_WINDOW = 0.10355339059327376220042218105242;		// this will guarentee no artifacts.   ( SIMPLEX_PYRAMID_HEIGHT - LENGTH_OF_CORNER_TO_CENTRE_OF_SIMPLEX_PYRAMID_FACE ) / 2.0,  ie (sqrt(0.5)-0.5) / 2.0
	hash_x = Cellular_weight_samples( hash_x ) * JITTER_WINDOW;
	hash_y = Cellular_weight_samples( hash_y ) * JITTER_WINDOW;
	hash_z = Cellular_weight_samples( hash_z ) * JITTER_WINDOW;

	//	offset the vectors.  ( and also scale so we can have a nice 0.0->1.0 range )
	const float INV_SIMPLEX_PYRAMID_HEIGHT = 1.4142135623730950488016887242097;	//	1.0 / sqrt( 0.5 )
	v1234_x *= INV_SIMPLEX_PYRAMID_HEIGHT;
	v1234_y *= INV_SIMPLEX_PYRAMID_HEIGHT;
	v1234_z *= INV_SIMPLEX_PYRAMID_HEIGHT;
	v1234_x += hash_x;
	v1234_y += hash_y;
	v1234_z += hash_z;

	//	calc the distance^2 to the closest point
	vec4 distsq = v1234_x*v1234_x + v1234_y*v1234_y + v1234_z*v1234_z;
	return min( min( distsq.x, distsq.y ), min( distsq.z, distsq.w ) );
}
