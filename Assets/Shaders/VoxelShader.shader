// hlsl
// 코드를 참조하거나 사용해보고 생긴 문제점이나 발견하신 개선점을 댓글로 남겨주세요.감사합니다.

Shader "Custom/VoxelShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Main Color", Color) = (1,1,1,1)
        _PixelSize("Pixel Size", Float) = 0.04
        _CubeSize("Cube Size", Float) = 0.04
        _IsUnlit("bIsUnlit", Float) = 1.0
    }
        SubShader
        {
            Tags { "LightMode" = "ForwardBase"}
            LOD 100

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma geometry geom
                #pragma fragment frag
                #pragma target 5.0            
                #include "UnityCG.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                };

                struct v2g
                {
                    float4 pos : SV_POSITION;
                    float3 normal : NORMAL;
                    half2 uv : TEXCOORD0;
                    fixed4  color : COLOR0;
                };

                struct g2f
                {
                    float4 pos : SV_POSITION;
                    float3 normal : NORMAL;
                    half2 uv : TEXCOORD0;
                    fixed4  color : COLOR0;
                    UNITY_FOG_COORDS(1)
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                uniform float _PixelSize;
                uniform float4 _Color;
                uniform float _CubeSize;
                uniform float _IsUnlit;

                v2g vert(appdata v)
                {
                    v2g o;

                    o.pos = float4(floor(v.vertex.xyz / _PixelSize) * _PixelSize, 1.0);

                    o.normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);

                    float2 scaledUV = v.uv * _MainTex_ST.xy;
                    float2 offsetUV = scaledUV + _MainTex_ST.zw;
                    o.uv = offsetUV;

                    o.color = tex2Dlod(_MainTex, float4(o.uv, 0, 0)) * _Color;

                    return o;
                }

                [maxvertexcount(36)]
                void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
                {
                    float3 positions[8] = {
                        float3(-0.5, -0.5, 0.5) * _CubeSize, // front right down
                        float3(0.5, -0.5, 0.5) * _CubeSize,  // front left down
                        float3(-0.5, 0.5, 0.5) * _CubeSize,  // front right top
                        float3(0.5, 0.5, 0.5) * _CubeSize,   // front left top
                        float3(-0.5, -0.5, -0.5) * _CubeSize,// back right down
                        float3(0.5, -0.5, -0.5) * _CubeSize, // back left down
                        float3(-0.5, 0.5, -0.5) * _CubeSize, // back right top
                        float3(0.5, 0.5, -0.5) * _CubeSize   // back left top
                    };

                    int indices[36] = {
                        0, 1, 3,  3, 2, 0,  // front face
                        5, 4, 6,  6, 7, 5,  // back face
                        0, 2, 4,  2, 6, 4,  // left face
                        7, 3, 1,  5, 7, 1,  // right face
                        4, 1, 0,  4, 5, 1,  // bottom face
                        2, 3, 6,  3, 7, 6   // top face
                    };

                    float3 dirIndexes[6] = {
                        float3(0, 0, 1), // front
                        float3(0, 0, -1), // back
                        float3(-1, 0, 0), // left
                        float3(1, 0, 0), // right
                        float3(0, -1, 0), // bottom
                        float3(0, 1, 0) // top
                    };

                    for (int i = 0; i < 36; i++)
                    {

                        if (i % 3 == 0) {
                            g2f o1, o2, o3;
                            o1.pos = UnityObjectToClipPos(float4(IN[0].pos.xyz + positions[indices[i]], 1.0));
                            o2.pos = UnityObjectToClipPos(float4(IN[0].pos.xyz + positions[indices[i + 1]], 1.0));
                            o3.pos = UnityObjectToClipPos(float4(IN[0].pos.xyz + positions[indices[i + 2]], 1.0));

                            o1.normal = dirIndexes[floor(i / 6)];
                            o2.normal = dirIndexes[floor(i / 6)];
                            o3.normal = dirIndexes[floor(i / 6)];

                            o1.uv = IN[0].uv;
                            o2.uv = IN[0].uv;
                            o3.uv = IN[0].uv;

                            o1.color = IN[0].color;
                            o2.color = IN[0].color;
                            o3.color = IN[0].color;

                            triStream.Append(o1);
                            triStream.Append(o2);
                            triStream.Append(o3);

                            triStream.RestartStrip();
                        }
                    }
                }

                fixed4 frag(g2f IN) : SV_Target
                {

                    fixed4 col = tex2D(_MainTex, IN.uv);

                    if (_IsUnlit > 0) {
                        col.rgb *= _Color;
                        return col;
                    }
                    else {
                        // main light 
                        float3 norm = normalize(IN.normal);
                        float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                        float diff = max(dot(norm, lightDir), 0.0);
                        col.rgb *= _Color * diff;

                        // sub lights
                        for (int i = 0; i < 4; i++) {
                            float dist = (1 / min(distance(float3(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i]), 0.001), IN.pos));
                            float3 lightDir = normalize(float3(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i]));
                            float diff = max(dot(norm, lightDir), 0.0);
                            col.rgb += _Color * dist * unity_4LightAtten0[i] * diff * unity_LightColor[i];
                        }

                        return col;
                    }
                }
                ENDCG
            }
        }
}
