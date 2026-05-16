# Raqib

**The persistent autonomous agent runtime for the ANKA mesh.**

Raqib -- رقيب -- means the continual witness, the watcher, the recorder. The one who observes and never forgets.

Raqib is the fourth layer of the AI-native internet stack.

    Bay2    <- what exists        (operational substrate)
    ANKA    <- what is claimed    (epistemic coordination)
    Dalil   <- how to navigate    (AI-native browser)
    Raqib   <- who is watching    (autonomous agent runtime)

---

## What Raqib Does

Raqib provides the execution loop that turns a stateless Dalil navigator into a persistent autonomous agent.

Without Raqib, an AI can browse the mesh.
With Raqib, an AI can live on the mesh.

The agent loop:

    loop:
      observe subscribed claim spaces
      filter for unseen claims
      deliberate on each claim
      witness claims that meet threshold
      challenge claims that contradict stance
      publish responses with evidence
      update memory and stances
      sleep, repeat

---

## Core Primitives

    raqib.make_identity(name, institution, node_address)
      Create a persistent agent identity.

    raqib.empty_memory()
      Initialize agent memory: stances, witnessed, challenged, published, seen.

    raqib.update_stance(memory, stance)
      Record or update the agent's position on a subject.

    raqib.get_stance(memory, claim_space, subject)
      Retrieve the agent's current position on a subject.

    raqib.default_deliberate(claim, memory, config)
      Rule-based deliberation: witness if score >= threshold,
      challenge if contradicts stance and score is low, ignore otherwise.

    raqib.observe(dalil, identity, memory, claim_spaces, since_timestamp)
      Pull new claims from the mesh. Filter for unseen. Update memory.

    raqib.act(dalil, identity, memory, deliberation, timestamp)
      Execute a deliberation: witness, challenge, or ignore.

    raqib.step(dalil, identity, memory, config, since_timestamp, timestamp)
      One full agent cycle: observe, deliberate, act, return updated memory.

    raqib.publish(dalil, identity, memory, claim_space, subject, finding, evidence_refs, timestamp)
      Publish a new claim. Update memory with stance and published digest.

---

## The Deliberation Slot

The default_deliberate function is a starting point, not a prescription.
Replace it with any reasoning system: an LLM call, a logic engine, a trained classifier.
Raqib provides the loop. The agent provides the judgment.

---

## Multi-Agent Institutional Societies

Once multiple Raqib instances are running, institutional societies emerge naturally.

    Oxford agent    watches research.result.claims
    MIT agent       watches reproducibility.results
    DeepMind agent  watches model.training.trace
    Hospital agent  watches dataset.provenance

They interact through ANKA without calling each other directly.
The mesh is the coordination layer.
Raqib is what makes them persistent.

---

## Language

Written in [Fard](https://github.com/mauludsadiq/FARD).
Requires Dalil: https://github.com/mauludsadiq/Dalil
Requires ANKA: https://github.com/mauludsadiq/Anka
