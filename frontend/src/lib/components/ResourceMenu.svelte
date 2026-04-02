<script lang="ts">
	import { PUBLIC_API_BASE_URL } from '$env/static/public';
	import { Popover, Dialog } from 'bits-ui';

	import DotsThreeVerticalIcon from 'phosphor-svelte/lib/DotsThreeVerticalIcon';
	import FlagIcon from 'phosphor-svelte/lib/FlagIcon';
	import TrashIcon from 'phosphor-svelte/lib/TrashIcon';
	import CheckIcon from 'phosphor-svelte/lib/CheckIcon';

	let {
		resourceId,
		isOwner = false,
		ondelete
	}: {
		resourceId: number;
		isOwner?: boolean;
		ondelete?: () => void;
	} = $props();

	let open = $state(false);
	let deleting = $state(false);
	let reportOpen = $state(false);
	let reportStep = $state<'form' | 'sending' | 'done'>('form');
	let reason = $state('');

	async function handleDelete() {
		if (deleting) return;
		deleting = true;
		try {
			const res = await fetch(`${PUBLIC_API_BASE_URL}/api/resources/${resourceId}`, {
				method: 'DELETE',
				credentials: 'include'
			});
			if (res.ok) {
				open = false;
				ondelete?.();
			}
		} finally {
			deleting = false;
		}
	}

	async function handleReport() {
		if (!reason.trim()) return;
		reportStep = 'sending';
		try {
			const res = await fetch(`${PUBLIC_API_BASE_URL}/api/resources/${resourceId}/report`, {
				method: 'POST',
				credentials: 'include',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ reason: reason.trim() })
			});
			if (res.ok) {
				reportStep = 'done';
				setTimeout(() => {
					reportOpen = false;
					reportStep = 'form';
					reason = '';
				}, 1500);
			} else {
				reportStep = 'form';
			}
		} catch {
			reportStep = 'form';
		}
	}
</script>

<!-- svelte-ignore a11y_no_static_element_interactions -->
<!-- svelte-ignore a11y_click_events_have_key_events -->
<div onclick={(e) => e.stopPropagation()}>
	<Popover.Root bind:open>
		<Popover.Trigger
			class="p-1.5 text-zinc-700 hover:text-zinc-900 hover:bg-zinc-200 cursor-pointer rounded-none"
		>
			<DotsThreeVerticalIcon weight="bold" class="size-4" />
		</Popover.Trigger>
		<Popover.Content class="z-100 bg-zinc-50 border border-zinc-300 min-w-36" sideOffset={4}>
			{#if !isOwner}
				<button
					class="w-full flex items-center gap-2 px-3 py-2 text-sm text-zinc-600 hover:bg-zinc-100 cursor-pointer"
					onclick={() => {
						open = false;
						reportOpen = true;
					}}
				>
					<FlagIcon class="size-4" />Reportar
				</button>
			{/if}
			{#if isOwner}
				<button
					class="w-full flex items-center gap-2 px-3 py-2 text-sm text-red-600 hover:bg-red-50 cursor-pointer"
					onclick={handleDelete}
					disabled={deleting}
				>
					<TrashIcon class="size-4" />{deleting ? 'Eliminando...' : 'Eliminar'}
				</button>
			{/if}
		</Popover.Content>
	</Popover.Root>

	<Dialog.Root
		bind:open={reportOpen}
		onOpenChange={(v) => {
			if (!v) {
				reportStep = 'form';
				reason = '';
			}
		}}
	>
		<Dialog.Portal>
			<Dialog.Overlay class="fixed inset-0 z-50 bg-black/30" />
			<Dialog.Content
				class="fixed left-1/2 top-1/2 z-50 w-full max-w-md -translate-x-1/2 -translate-y-1/2 bg-zinc-50 border border-zinc-300 p-6"
			>
				{#if reportStep === 'done'}
					<div class="flex flex-col items-center gap-3 py-4">
						<CheckIcon class="size-8 text-green-600" />
						<p class="text-zinc-700 text-center">
							Gracias por mejorar por mantener nuestra plataforma más segura
						</p>
					</div>
				{:else}
					<h2 class="text-lg text-zinc-700 mb-1">Reportar recurso</h2>
					<p class="text-sm text-zinc-500 mb-4">
						Describe el motivo por el que este recurso debería ser revisado.
					</p>
					<textarea
						bind:value={reason}
						placeholder="Ej: Contenido con copyright, spam, información incorrecta..."
						rows="4"
						class="w-full text-sm border border-zinc-300 bg-zinc-50 rounded-none px-3 py-2 resize-none focus:outline-none focus:border-indigo-300 mb-4"
					></textarea>
					<div class="flex justify-end gap-2">
						<button
							onclick={() => {
								reportOpen = false;
							}}
							class="px-4 py-2 text-zinc-600 border border-zinc-300 hover:bg-zinc-100 transition-colors cursor-pointer"
						>
							Cancelar
						</button>
						<button
							onclick={handleReport}
							disabled={reportStep === 'sending' || !reason.trim()}
							class="px-4 py-2 bg-red-200 text-red-700 hover:bg-red-100 transition-colors cursor-pointer disabled:opacity-50"
						>
							{reportStep === 'sending' ? 'Enviando...' : 'Enviar reporte'}
						</button>
					</div>
				{/if}
			</Dialog.Content>
		</Dialog.Portal>
	</Dialog.Root>
</div>
