---
layout: post
title: "Machine Learning Fundamentals: What I Wish Someone Had Told Me Earlier"
date: 2025-11-25
tags: [Machine Learning, AI, Fundamentals, Beginner Friendly, Data Science]
excerpt: "ML jargon can feel like a foreign language. Here's my attempt to explain supervised vs unsupervised learning, gradient descent, loss functions, regularization, and hyperparameter tuning using everyday examples that actually make sense."
---

# Machine Learning Fundamentals: What I Wish Someone Had Told Me Earlier

*Published on November 25, 2025*

A few months ago, I was having coffee with a friend who's a product manager. She asked me what "gradient descent" means, and I completely blanked. Not because I don't know it—I use it every day—but because I realized I'd never actually had to explain it to someone outside the ML bubble.

That conversation stuck with me. So here's my attempt to explain the core ML concepts the way I wish someone had explained them to me when I started.

## Supervised vs. Unsupervised Learning: The Study Group Analogy

Imagine you're back in school, studying for an exam.

**Supervised learning** is like studying with a really good answer key. You look at a practice problem, try to solve it, then check the answer. Got it wrong? You adjust your thinking. Over time, you start recognizing patterns—"Oh, whenever I see X, the answer is usually Y."

That's exactly how supervised learning works. You feed the algorithm examples where you *already know* the right answer (we call these "labels"). The algorithm learns the patterns and eventually can make predictions on new, unseen data.

Examples you've probably used:
- Email spam filters (learns from emails you've marked as spam)
- Netflix recommendations (learns from movies you've rated)
- Voice assistants recognizing your speech

**Unsupervised learning** is more like being dropped into a library with no guidance. Nobody tells you what's important—you just start noticing things yourself. "Hey, these books all have similar covers. And these ones seem to be about the same topics."

The algorithm finds patterns and groupings *without* being told what to look for.

Real-world examples:
- Customer segmentation (grouping shoppers by behavior without predefined categories)
- Anomaly detection (finding weird transactions in your bank account)
- Organizing photo libraries by similar faces

Here's the key difference I tell people: **supervised learning is like learning with a teacher, unsupervised learning is like being a detective.**

## Gradient Descent: Finding the Bottom of a Valley (Blindfolded)

This one is my favorite to explain because once it clicks, you never forget it.

Imagine you're dropped somewhere on a hilly landscape, blindfolded. Your goal? Get to the lowest point in the valley. You can't see anything, but you *can* feel the slope under your feet.

What would you do?

You'd probably:
1. Feel which direction slopes downward
2. Take a step in that direction
3. Feel the slope again
4. Repeat until you're not going down anymore

That's gradient descent. Seriously, that's it.

In ML terms:
- The "landscape" is your loss function (how wrong your predictions are)
- The "slope" is the gradient (mathematical direction of steepest increase)
- Taking a step is updating your model's parameters
- "Downward" means reducing the error

**The learning rate** (we'll talk more about this later) is basically how big your steps are. Too big? You might overshoot the bottom and climb up the other side. Too small? You'll take forever to get anywhere.

I sometimes picture a marble rolling down a bowl. It naturally finds the bottom—that's the intuition behind gradient descent.

### A Quick Thought Experiment

Think about tuning the temperature in your shower. You start too cold, so you turn it up. Now it's too hot, so you turn it down a bit. You keep adjusting until it feels *just right*.

That's gradient descent in action—you're making small adjustments based on feedback (too hot/too cold) until you minimize your discomfort. The "gradient" is the feedback telling you which way to turn.

## Loss Function: Your Model's Report Card

Here's a concept that confused me for the longest time because nobody explained *why* we need it.

A loss function (sometimes called objective function or cost function—same thing, different names) answers one simple question: **How wrong is my model right now?**

Think of it like this. You're playing darts:
- Your "model" is your throwing technique
- Each throw is a prediction
- The bullseye is the actual correct answer
- The loss function measures how far from the bullseye you landed

If you hit the bullseye, your loss is zero—perfect prediction. The further away you land, the higher the loss.

Different problems need different loss functions. Missing by 2 inches might matter a lot for brain surgery, but not so much for horseshoes. That's why we have:

- **Mean Squared Error**: Penalizes big mistakes heavily (squares the errors)
- **Absolute Error**: Treats all mistakes equally
- **Cross-Entropy**: Used when you're classifying things (spam vs. not spam)

The key insight: **gradient descent uses the loss function to figure out which way is "down."** Without a loss function, the algorithm wouldn't know if it's getting better or worse.

## Regularization: Teaching Your Model to Not Be a Know-It-All

This one's subtle but incredibly important.

Imagine a student who memorizes every single word in the textbook for an exam. They can recite any page perfectly. But then the exam asks them to apply the concepts to a *new* problem they've never seen—and they freeze.

That's overfitting. The model learned the training data *too well*, including all the noise and random quirks that won't appear in new data.

**Regularization** is basically telling your model: "Hey, don't get too fancy. Keep things simple."

Here's my favorite analogy. You know how some people pack for a trip and bring *everything*? "I might need this umbrella, and these three types of shoes, and this backup phone charger..." Their suitcase weighs 50 kg.

Regularization is like telling them: "Every item has a cost. Only bring what you really need."

In ML, regularization adds a penalty for complexity. The model can still learn complex patterns, but it has to "pay" for them. This forces it to focus on patterns that genuinely matter.

**L1 regularization** (Lasso): "Each extra feature costs a flat fee" → tends to eliminate useless features entirely

**L2 regularization** (Ridge): "Each extra feature costs proportionally to how much you use it" → shrinks feature importance but rarely eliminates

The result? A model that doesn't memorize—it actually *learns*.

## Generalization: The Whole Point of All This

Here's something that took me way too long to internalize: **We don't care how well a model performs on data it's already seen.**

Let me say that again because it's that important.

If I show you 100 photos and ask you to memorize which ones have cats, you could get 100% accuracy on those specific photos. But that doesn't mean you *understand* what a cat looks like. Can you recognize a cat in a photo you've never seen?

That's generalization—performing well on new, unseen data.

Everything we do in ML is in service of this goal:
- We split data into training and test sets (to check if we're actually learning)
- We use regularization (to prevent memorizing)
- We tune hyperparameters carefully (to find the sweet spot)

I like to think of it like learning to cook. You don't want to only make your mom's exact recipe perfectly. You want to understand cooking well enough to adapt when you're missing an ingredient or trying a new dish.

**A model that can't generalize is basically useless**—no matter how impressive its training accuracy looks.

## Hyperparameter Tuning: Finding the Perfect Recipe

Okay, this is where it gets practical.

Hyperparameters are settings you choose *before* training starts. They're not learned from the data—you have to pick them yourself.

Think of it like baking a cake:
- The **ingredients** are your data
- The **recipe instructions** are your model architecture
- The **oven temperature and baking time** are your hyperparameters

You can have the best ingredients and recipe in the world, but bake at the wrong temperature? Disaster.

Common hyperparameters you'll encounter:
- **Learning rate**: How big steps to take during gradient descent (too high = chaotic, too low = takes forever)
- **Number of layers/neurons**: How complex the model can be
- **Regularization strength**: How much to penalize complexity
- **Batch size**: How many examples to look at before adjusting

**How do you find good hyperparameters?**

Honestly? Trial and error, but systematic.

1. **Grid search**: Try every combination (slow but thorough)
2. **Random search**: Randomly sample combinations (surprisingly effective)
3. **Bayesian optimization**: Smart guessing based on previous results

Here's what nobody tells beginners: there's no "correct" answer. Different problems need different settings. It's genuinely an art as much as a science.

My personal approach: start with defaults from whatever library you're using, train a baseline model, then tweak one thing at a time. Keep notes on what works. Over time, you develop intuition.

## Putting It All Together

Let me tie everything together with a story.

Imagine you're teaching someone to play chess:

1. **Supervised learning**: You show them famous games with commentary. "This move was good because..." They learn from examples with known outcomes.

2. **Loss function**: After each game they play, you give them a score based on their performance.

3. **Gradient descent**: They adjust their strategy bit by bit, based on what worked and what didn't.

4. **Regularization**: You tell them not to memorize specific openings, but to understand *principles* that apply broadly.

5. **Hyperparameters**: You decide how many games to play per day, how much feedback to give, how long to think per move—settings that affect learning but aren't the learning itself.

6. **Generalization**: The goal isn't to replay the famous games perfectly—it's to beat opponents they've never faced before.

That's machine learning in a nutshell.

## Final Thoughts

I've been working with ML for years now, and honestly, these fundamentals still come up every single day. When a model isn't working, nine times out of ten, it's one of these basics that's off.

The fancy stuff—transformers, diffusion models, whatever's trending on Twitter this week—it's all built on these foundations. Nail these concepts, and the rest becomes much more approachable.

Got questions? I probably glossed over something that deserves more attention. Drop me a message—I genuinely enjoy these conversations.

---

*This post is part of a series where I try to explain technical concepts without the jargon. If you found this helpful, you might also like my posts on [distributed rate limiting](/2025/09/18/distributed-rate-limiter-spring-boot-redis.html).*
