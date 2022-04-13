#ifndef _GBUFFER_BASE_HLSL_
#define _GBUFFER_BASE_HLSL_

#define MaterialID_Lit                    1 
#define MaterialID_Anisotropic            2 
#define MaterialID_Clearcoat              3 
#define MaterialID_Cloth                  4 
#define MaterialID_SubSurfaceScattering   5 
#define MaterialID_Max                    6 

float EncodeMaterialID(int ID)
{
    return (float)ID*rcp(MaterialID_Max);
}

int DecodeMaterialID(float fID)
{
    return (int)( ceil(fID * MaterialID_Max) );
}


#endif