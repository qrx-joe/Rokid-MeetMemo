// services/parser.js
//
// "Zero parsing + good interaction" — see Docs/SPEC.md §6.1.
//
// Phase 1: this function does NOT attempt to extract name, role,
// organization, dates, or actions from free text. The entire input is
// preserved verbatim in `notes`. Every structured field is left blank
// (or '待补充' where SPEC mandates an explicit placeholder), so the
// confirmation card in pages/capture is the user's chance to author them
// directly. This is deliberate: fragile regex pattern matching produces
// confidently-wrong fields, and any heuristic written here becomes
// throwaway code the day Phase 2 wires an LLM in.
//
// Phase 2: replace the body of `parse` with a single LLM call returning
// the same shape. Apply schema validation. Unknown fields STILL stay
// blank/'待补充' — the LLM must not be allowed to invent missing facts.
//
// DO NOT add Chinese-language regex, date-fragment parsing, or
// keyword spotting here. If you find yourself reaching for `.match()`,
// re-read SPEC.md §6.2.

/**
 * @typedef {Object} ContactDraft
 * @property {string|null} id          - null until contact-store assigns one on save
 * @property {string}      name
 * @property {string}      role
 * @property {string}      organization
 * @property {string}      context
 * @property {string[]}    interests
 * @property {string}      nextAction
 * @property {string}      followUpAt   - ISO date string 'YYYY-MM-DD' once set
 * @property {string}      notes
 */

/**
 * @typedef {Object} ParseResult
 * @property {ContactDraft} contact   - draft with notes filled, structured fields blank
 * @property {'needs-input'|'parsed'|'error'} status
 * @property {string} [message]       - human-readable hint for the UI when not 'parsed'
 */

/**
 * Parse a quick-note input string into a contact draft.
 *
 * @param {string} rawText
 * @returns {ParseResult}
 */
export function parse(rawText) {
  const text = typeof rawText === 'string' ? rawText.trim() : '';

  return {
    contact: {
      id: null,
      name: '',
      role: '',
      // Keep the placeholder explicit so the UI knows to ask. SPEC.md §7.
      organization: '待补充',
      context: '',
      interests: [],
      nextAction: '',
      followUpAt: '',
      notes: text
    },
    // Always 'needs-input' in Phase 1 — there is nothing to confirm because
    // nothing was inferred. The capture page reads this and routes the user
    // straight to the editable confirmation card.
    status: 'needs-input',
    message: text
      ? '已记录原文，请在下一步补全字段。'
      : '输入为空。'
  };
}

export const parser = { parse };
