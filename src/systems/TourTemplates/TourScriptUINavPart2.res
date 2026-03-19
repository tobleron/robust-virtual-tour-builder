let script = `

        const countdownNumber = document.createElement("span");
        countdownNumber.className = "portrait-mode-selector-countdown-number";
        countdownNumber.textContent = String(autoTourHomeReturnCountdownRemaining);

        countdown.appendChild(countdownLabel);
        countdown.appendChild(countdownNumber);
        panel.appendChild(countdown);
      }
      if (typeof syncPortraitModeSelectorClasses === "function") {
        syncPortraitModeSelectorClasses();
      }
      updatePortraitJoystick();
    }
    function updateExportRoomLabel(sceneId, animateOnShow) {
      const labelEl = document.getElementById("viewer-room-label-export");
      if (!labelEl) return;
      labelEl.classList.remove("state-shortcut-animate");
      const clearLabel = () => {
        while (labelEl.firstChild) labelEl.removeChild(labelEl.firstChild);
        labelEl.classList.remove("state-shortcut-animate");
        labelEl.classList.remove("state-visible");
        labelEl.classList.add("state-hidden");
      };
      const getSceneNumber = sid => {
        const rawSceneNumber = scenesData?.[sid]?.sceneNumber;
        return Number.isInteger(rawSceneNumber) && rawSceneNumber >= 1 ? rawSceneNumber : null;
      };
      const rawLabel = typeof scenesData[sceneId]?.label === "string" ? scenesData[sceneId].label.trim() : "";
      if (rawLabel !== "") {
        while (labelEl.firstChild) labelEl.removeChild(labelEl.firstChild);
        const seqNo = getSceneNumber(sceneId);
        const seqEl = document.createElement("span");
        seqEl.className = "viewer-persistent-label-export-seq";
        seqEl.textContent = "# " + (Number.isInteger(seqNo) ? String(seqNo) : "-");
        const nameEl = document.createElement("span");
        nameEl.className = "viewer-persistent-label-export-name";
        nameEl.textContent = rawLabel;
        labelEl.appendChild(seqEl);
        labelEl.appendChild(nameEl);
        labelEl.classList.remove("state-hidden");
        labelEl.classList.add("state-visible");
        if (animateOnShow === true) {
          void labelEl.offsetWidth;
          labelEl.classList.add("state-shortcut-animate");
        }
        return;
      }
      clearLabel();
    }
    function buildSceneNumberRows() {
      const sceneNumberRows = [];
      if (scenesData && typeof scenesData === "object") {
        Object.entries(scenesData).forEach(([sceneId, sceneData]) => {
          const sceneNumber = Number.isInteger(sceneData?.sceneNumber) ? sceneData.sceneNumber : null;
          if (Number.isInteger(sceneNumber) && sceneNumber >= 1) {
            sceneNumberRows.push({ sceneNumber, sceneId });
          }
        });
      }
      sceneNumberRows.sort((a, b) => a.sceneNumber - b.sceneNumber);
      return sceneNumberRows;
    }
    function navigateToSceneByNumberValue(chosen, options) {
      if (!Number.isInteger(chosen) || chosen < 1) return false;
      const sceneNumberRows = buildSceneNumberRows();
      if (sceneNumberRows.length === 0) return false;
      const targetEntry = sceneNumberRows.find(item => item.sceneNumber === chosen);
      if (!targetEntry || !targetEntry.sceneId) return false;
      navigateToFloorTagShortcut(targetEntry.sceneId, options);
      return true;
    }
    function isSceneSequencePromptOpen() {
      return mapSequenceInputState.isOpen === true;
    }
    function syncSceneSequencePromptHostState() {
      if (!document || !document.body) return;
      document.body.classList.toggle("is-sequence-prompt-open", mapSequenceInputState.isOpen === true);
      const host = getSceneSequencePromptHost();
      if (!host) return;
      host.classList.toggle("state-hidden", mapSequenceInputState.isOpen !== true);
      host.setAttribute("aria-hidden", mapSequenceInputState.isOpen === true ? "false" : "true");
    }
    function closeSceneSequencePrompt() {
      mapSequenceInputState.isOpen = false;
      mapSequenceInputState.error = "";
      mapSequenceInputState.value = "";
      removeMapSequencePromptPanel();
      syncSceneSequencePromptHostState();
      if (typeof updateNavShortcutsV2 === "function") {
        const sid = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId;
        if (sid) updateNavShortcutsV2(sid, true);
      }
    }
    function submitSceneSequencePrompt() {
      const normalized = String(mapSequenceInputState.value || "").trim().toLowerCase();
      if (normalized === "") {
        mapSequenceInputState.error = "enter a scene number";
        return false;
      }
      if (normalized === "e") {
        closeSceneSequencePrompt();
        return true;
      }
      const chosen = Number.parseInt(normalized, 10);
      const didNavigate = navigateToSceneByNumberValue(chosen, {
        fromSceneSequencePrompt: true,
      });
      if (!didNavigate) {
        mapSequenceInputState.error = "invalid scene";
        return false;
      }
      mapSequenceInputState.error = "";
      closeSceneSequencePrompt();
      return true;
    }
    function openSceneSequencePrompt() {
      const interactionShell =
        typeof resolveExportInteractionShell === "function"
          ? resolveExportInteractionShell()
          : "classic";
      if (interactionShell !== "classic") return false;
      const rows = buildSceneNumberRows();
      if (rows.length === 0) return false;
      if (typeof suspendLookingModeForSceneSequencePrompt === "function") {
        suspendLookingModeForSceneSequencePrompt();
      }
      mapSequenceInputState.isOpen = true;
      mapSequenceInputState.error = "";
      mapSequenceInputState.value = "";
      syncSceneSequencePromptHostState();
      if (typeof renderMapSequencePromptPanel === "function") {
        renderMapSequencePromptPanel();
      }
      if (typeof updateNavShortcutsV2 === "function") {
        const sid = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId;
        if (sid) updateNavShortcutsV2(sid, true);
      }
      return true;
    }
    function navigateToSceneBySequenceInput() {
      return openSceneSequencePrompt();
    }
    function removeMapSequencePromptPanel() {
      const host = getSceneSequencePromptHost();
      if (host) {
        while (host.firstChild) host.removeChild(host.firstChild);
      }
      const existing = document.getElementById("viewer-map-sequence-prompt-export");
      if (existing && existing.parentNode) {
        existing.parentNode.removeChild(existing);
      }
    }
    function renderMapSequencePromptPanel() {
      removeMapSequencePromptPanel();
      syncSceneSequencePromptHostState();
      const host = getSceneSequencePromptHost();
      if (!host || mapSequenceInputState.isOpen !== true) return;
      const rows = buildSceneNumberRows();
      const maxSceneNumber = rows.length > 0 ? rows[rows.length - 1].sceneNumber : 0;
      const prompt = document.createElement("div");
      prompt.id = "viewer-map-sequence-prompt-export";
      prompt.className = "map-sequence-prompt-export";

      const title = document.createElement("div");
      title.className = "map-sequence-prompt-title";
      title.textContent = "Jump to scene";

      const controls = document.createElement("div");
      controls.className = "map-sequence-prompt-controls";

      const input = document.createElement("input");
      input.type = "text";
      input.className = "map-sequence-prompt-input";
      input.setAttribute("inputmode", "numeric");
      input.setAttribute("autocomplete", "off");
      input.setAttribute("spellcheck", "false");
      input.setAttribute("aria-label", "Scene number input");
      input.placeholder = maxSceneNumber > 0 ? "1-" + String(maxSceneNumber) : "";
      input.value = String(mapSequenceInputState.value || "");
      input.addEventListener("input", event => {
        mapSequenceInputState.value = event?.target?.value ?? "";
        mapSequenceInputState.error = "";
      });

      const goBtn = document.createElement("button");
      goBtn.type = "button";
      goBtn.className = "map-sequence-prompt-btn";
      goBtn.textContent = "go";
      goBtn.addEventListener("click", () => {
        const didSubmit = submitSceneSequencePrompt();
        if (!didSubmit && typeof updateNavShortcutsV2 === "function") {
          const sid = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId;
          if (sid) updateNavShortcutsV2(sid, true);
        }
      });

      const exitHint = document.createElement("div");
      exitHint.className = "map-sequence-prompt-exit-hint";
      exitHint.textContent = "n to return";

      controls.appendChild(input);
      controls.appendChild(goBtn);
      prompt.appendChild(title);
      prompt.appendChild(controls);
      prompt.appendChild(exitHint);

      if (mapSequenceInputState.error && mapSequenceInputState.error !== "") {
        const errorEl = document.createElement("div");
        errorEl.className = "map-sequence-prompt-error";
        errorEl.textContent = mapSequenceInputState.error;
        prompt.appendChild(errorEl);
      }

      host.appendChild(prompt);
      setTimeout(() => {
        try {
          input.focus({ preventScroll: true });
          input.select();
        } catch (_err) {
          input.focus();
        }
      }, 0);
    }
    function navigateToFloorTagShortcut(targetSceneId, options) {
      if (!window.viewer || typeof window.viewer.getScene !== "function") return;
      const fromMap = options?.fromMap === true;
      const fromSceneSequencePrompt = options?.fromSceneSequencePrompt === true;
      const mapSelectedRow = options?.mapSelectedRow ?? null;
      const sequencePosition =
        Number.isInteger(options?.sequencePosition) && options.sequencePosition >= 1
          ? options.sequencePosition
          : null;
      const selectedDurationMs = 500;
      const runNavigation = () => {
        if (fromMap && typeof enableLookingModeAfterMapNavigation === "function") {
          enableLookingModeAfterMapNavigation();
        }
        if (
          fromSceneSequencePrompt &&
          typeof restoreLookingModeAfterSceneSequencePromptSuccess === "function"
        ) {
          restoreLookingModeAfterSceneSequencePromptSuccess();
        }
        if (isExportMapOpen()) closeExportMap();
        const row = document.querySelector('.floor-tag-shortcut-row[data-scene-id="' + String(targetSceneId) + '"]');
        if (row) {
          row.classList.add("state-selected");
          setTimeout(() => {
            row.classList.remove("state-selected");
          }, selectedDurationMs);
        }
        const resolvedTargetSceneId = resolveExistingSceneId(targetSceneId);
        if (!resolvedTargetSceneId) return;
        if (window.viewer.getScene() === resolvedTargetSceneId) {
          if (Number.isInteger(sequencePosition) && typeof applyManualSequencePosition === "function") {
            applyManualSequencePosition(resolvedTargetSceneId, sequencePosition);
          }
          pendingShortcutLabelSceneId = resolvedTargetSceneId;
          updateExportRoomLabel(resolvedTargetSceneId, true);
          pendingShortcutLabelSceneId = null;
          updateNavShortcutsV2(resolvedTargetSceneId, true);
          return;
        }
        pendingShortcutLabelSceneId = resolvedTargetSceneId;
        navigateToNextScene(
          { targetSceneId: resolvedTargetSceneId },
          resolvedTargetSceneId,
          Number.isInteger(sequencePosition)
            ? {
                targetSceneId: resolvedTargetSceneId,
                sequenceCursorOverride: sequencePosition - 1,
              }
            : undefined,
        );
      };
      if (
        fromMap &&
        window.viewer.getScene() === targetSceneId &&
        !Number.isInteger(sequencePosition)
      ) {
        return;
      }
      if (fromMap && mapSelectedRow) {
        mapSelectedRow.classList.add("state-selected");
        setTimeout(() => {
          mapSelectedRow.classList.remove("state-selected");
          runNavigation();
        }, selectedDurationMs);
        return;
      }
      runNavigation();
    }
    function navigateToNextSequenceShortcut() {
      const sceneId = floorTagShortcutState.sceneId;
      const nextSceneId = floorTagShortcutState.nextSceneId;
      const nextHotspotIndex = floorTagShortcutState.nextHotspotIndex;
      const nextSequenceNumber = floorTagShortcutState.nextSequenceNumber;
      if (!sceneId || !nextSceneId) return false;
      if (!Number.isInteger(nextHotspotIndex) || nextHotspotIndex < 0) {
        navigateToNextScene(
          { sourceSceneId: sceneId, targetSceneId: nextSceneId },
          nextSceneId,
          { sourceSceneId: sceneId, targetSceneId: nextSceneId, sequenceCursorOverride: nextSequenceNumber },
        );
        return true;
      }
      const hotspot = scenesData?.[sceneId]?.hotSpots?.[nextHotspotIndex];
      if (!hotspot) {
        navigateToNextScene(
          { sourceSceneId: sceneId, targetSceneId: nextSceneId },
          nextSceneId,
          { sourceSceneId: sceneId, targetSceneId: nextSceneId, sequenceCursorOverride: nextSequenceNumber },
        );
        return true;
      }
      pendingShortcutLabelSceneId = nextSceneId;
      navigateToNextScene(
        {
          sourceSceneId: sceneId,
          i: nextHotspotIndex,
          targetSceneId: hotspot?.targetSceneId ?? nextSceneId,
          target: hotspot?.target,
          targetName: hotspot?.target,
          isReturnLink: hotspot?.isReturnLink === true,
        },
        nextSceneId,
        { sourceSceneId: sceneId, targetSceneId: nextSceneId, sequenceCursorOverride: nextSequenceNumber },
      );
      return true;
    }
    function navigateToPreviousSequenceShortcut() {
      const sceneId = floorTagShortcutState.sceneId;
      const prevSceneId = floorTagShortcutState.prevSceneId;
      const prevHotspotIndex = floorTagShortcutState.prevHotspotIndex;
      const prevSequenceNumber = floorTagShortcutState.prevSequenceNumber;
      if (!sceneId || !prevSceneId) return false;
`
