#ifndef TOJYNICK_MATH
#define TOJYNICK_MATH

const float Epsilon = 1e-10;

half GetSmoothnessPower(float rawSmoothness)
{
    return exp2(10 * rawSmoothness + 1);
}

half GetToonTone(half dotProduct, half amountOfTones, half threshold)
{
    half toneStep = threshold / (amountOfTones - 1);
    int currentToneIndex = floor(dotProduct / toneStep - 1);

    half result = 1 / (amountOfTones - 1) * currentToneIndex;
    
    return saturate(result);
}

#endif