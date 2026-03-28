<script lang="ts">
	import { PUBLIC_API_BASE_URL } from '$env/static/public';
	import { Popover } from 'bits-ui';

	import DotsThreeVerticalIcon from 'phosphor-svelte/lib/DotsThreeVerticalIcon';
	import FlagIcon from 'phosphor-svelte/lib/FlagIcon';
	import TrashIcon from 'phosphor-svelte/lib/TrashIcon';

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
					onclick={() => (open = false)}
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
</div>
