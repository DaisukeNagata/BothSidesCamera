//
//  BothSidesMixer.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/11/18.
//  Copyright © 2019 永田大祐. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MixerParameters
{
    float2 pipPosition;
    float2 pipSize;
};

constant sampler kBilinearSampler(filter::linear,  coord::pixel, address::clamp_to_edge);

// Compute kernel
kernel void reporterMixer(texture2d<half, access::read>      newfullScreenTexture       [[ texture(0) ]],
                          texture2d<half, access::sample>    pipMargin                  [[ texture(1) ]],
                          texture2d<half, access::sample>    pipInput                   [[ texture(2) ]],
                          texture2d<half, access::write>     outputTexture              [[ texture(3) ]],
                          const device    MixerParameters&   mixerParameters            [[ buffer(0) ]],
                          uint2 gid [[thread_position_in_grid]])

{
    uint2 pipPosition = uint2(mixerParameters.pipPosition);
    uint2 pipSize = uint2(mixerParameters.pipSize);

    half4 output;

    // Check if the output pixel should be from full screen or PIP
    if ( (gid.x >= pipPosition.x) && (gid.y >= pipPosition.y) &&
         (gid.x < (pipPosition.x + pipSize.x)) && (gid.y < (pipPosition.y + pipSize.y)) )
    {
        // Position and scale the PIP window
        float2 pipSamplingCoord =  float2(gid - pipPosition) * float2(pipInput.get_width(), pipInput.get_height()) / float2(pipSize);
        output = pipInput.sample(kBilinearSampler, pipSamplingCoord + pipMargin.get_height());
    }
    else
    {
        output = newfullScreenTexture.read(gid);
    }

    outputTexture.write(output, gid);
}
