{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE EmptyDataDecls #-}

-- | This module contains the type classes for manipulating distributions.
--
-- We use the same classes for both discrete and continuous distributions.  Unfortunately, we cannot use the type classes from the 'statistics' package because we require more flexibility than they offer.

module HLearn.Models.Distributions.Common
    ( 
    -- * Type classes
    Probabilistic(..)
    , CDF(..)
    , PDF(..)
    , Mean(..)
    , Variance(..)
    
    -- * Utility functions
    , nonoverlap
    )
    where

import Data.List
import HLearn.Algebra

-------------------------------------------------------------------------------
-- Distribution

-- | 
class Probabilistic model where
    type Probability model

-- |  Technically, every distribution has a Cumulative Distribution Function (CDF), and so this type class should be merged with the "Distribution" type class.  However, I haven't had a chance to implement the CDF for most distributions yet, so this type class has been separated out.
class (Probabilistic dist) => CDF dist where
-- class CDF dist dp prob | dist -> dp, dist -> prob where
    cdf :: dist -> Datapoint dist -> Probability dist
    cdfInverse :: dist -> Probability dist -> Datapoint dist

-- | Not every distribution has a Probability Density Function (PDF), however most distributions in the HLearn library do.  For many applications, the PDF is much more intuitive and easier to work with than the CDF.  For discrete distributions, this is often called a Probability Mass Function (PMF); however, for simplicity we use the same type class for both continuous and discrete data.
class (Probabilistic dist) => PDF dist where
    pdf :: dist -> Datapoint dist -> Probability dist

class (HomTrainer dist) => Mean dist where
    mean :: dist -> Datapoint dist
    
class (Probabilistic dist) => Variance dist where
    variance :: dist -> Probability dist


-- class PDF dist dp prob | dist -> dp, dist -> prob where
--     pdf :: dist -> dp -> prob 
    

--     mean :: dist -> sample
--     drawSample :: (RandomGen g) => dist -> Rand g sample

-- class (Distribution dist dp prob) => DistributionOverlap dist dp prob where
--     overlap :: [dist] -> prob
    
-- instance DistributionOverlap dist Double prob where
--     overlap xs = fmap (sort . (flip pdf) [-10..10]) xs

-------------------------------------------------------------------------------
-- Continuity

data Discrete 
data Continuous

type family Continuity t :: *
type instance Continuity Int = Discrete
type instance Continuity Integer = Discrete
type instance Continuity Char = Discrete
type instance Continuity String = Discrete

type instance Continuity Float = Continuous
type instance Continuity Double = Continuous
type instance Continuity Rational = Continuous

-------------------------------------------------------------------------------
-- Utilities

-- | If you were to plot a list of distributions, nonoverlap returns the amount of area that only a single distribution covers.  That is, it will be equal to number of distributions - the overlap.
--
-- This function is used by the HomTree classifier.
nonoverlap :: 
    ( Enum (Probability dist), Fractional (Probability dist), Ord (Probability dist)
    , PDF dist
    , CDF dist
    ) => [dist] -> Probability dist
nonoverlap xs = (sum scoreL)/(fromIntegral $ length scoreL)
    where
        scoreL = fmap (diffscore . reverse . sort . normalizeL) $ transpose $ fmap ((flip fmap) sampleL . pdf) xs
        samplelen = length sampleL
        sampleL = concat $ fmap sampleDist xs
        sampleDist dist = fmap (cdfInverse dist . (/100)) [1..99]
        
diffscore :: (Num prob) => [prob] -> prob
diffscore (x1:x2:xs) = x1-x2

weightedscore :: (Num prob) => [prob] -> prob
weightedscore = sum . fmap (\(i,v) -> (fromIntegral i)*v) . zip [0..]
        
normalizeL :: (Fractional a) => [a] -> [a]
normalizeL xs = fmap (/tot) xs
    where
        tot = sum xs
