import React, { createContext, useCallback, useContext, useMemo, useState } from "react";
import { BeaconModal } from "../components/ui/BeaconModal";
import { Button } from "../components/ui/button";

type Pending = {
  entityLabel: string;
  displayName?: string;
  resolve: (ok: boolean) => void;
};

const DeleteConfirmContext = createContext<((entityLabel: string, displayName?: string) => Promise<boolean>) | null>(
  null,
);

export function DeleteConfirmProvider({ children }: { children: React.ReactNode }) {
  const [pending, setPending] = useState<Pending | null>(null);

  const confirmDelete = useCallback((entityLabel: string, displayName?: string) => {
    return new Promise<boolean>((resolve) => {
      setPending({ entityLabel, displayName, resolve });
    });
  }, []);

  const finish = useCallback((ok: boolean) => {
    setPending((p) => {
      if (!p) return null;
      p.resolve(ok);
      return null;
    });
  }, []);

  const cancelDelete = useCallback(() => finish(false), [finish]);
  const affirmDelete = useCallback(() => finish(true), [finish]);

  const body = useMemo(() => {
    if (!pending) return null;
    const who = pending.displayName?.trim() ? ` "${pending.displayName.trim()}"` : "";
    return (
      <p className="text-sm text-muted-foreground font-medium leading-relaxed">
        Delete {pending.entityLabel}
        {who}?
        <br />
        <span className="text-destructive/90 font-bold">This cannot be undone.</span>
      </p>
    );
  }, [pending]);

  return (
    <DeleteConfirmContext.Provider value={confirmDelete}>
      {children}
      <BeaconModal
        isOpen={pending !== null}
        onClose={cancelDelete}
        title="Confirm delete"
        maxWidth="max-w-md"
        footer={
          <>
            <Button
              variant="ghost"
              type="button"
              className="uppercase font-black italic text-xs tracking-widest"
              onClick={cancelDelete}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              type="button"
              className="uppercase font-black italic text-xs tracking-widest"
              onClick={affirmDelete}
            >
              Delete
            </Button>
          </>
        }
      >
        {body}
      </BeaconModal>
    </DeleteConfirmContext.Provider>
  );
}

/** @see DeleteConfirmProvider */
// eslint-disable-next-line react-refresh/only-export-components -- hook must live next to provider context
export function useDeleteConfirm(): (entityLabel: string, displayName?: string) => Promise<boolean> {
  const ctx = useContext(DeleteConfirmContext);
  if (!ctx) {
    throw new Error("useDeleteConfirm must be used within DeleteConfirmProvider");
  }
  return ctx;
}
