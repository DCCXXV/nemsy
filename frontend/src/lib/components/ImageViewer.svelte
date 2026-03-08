<script lang="ts">
	import MagnifyingGlassPlusIcon from 'phosphor-svelte/lib/MagnifyingGlassPlusIcon';
	import MagnifyingGlassMinusIcon from 'phosphor-svelte/lib/MagnifyingGlassMinusIcon';

	let {
		src,
		alt = 'preview'
	}: {
		src: string;
		alt?: string;
	} = $props();

	let zoom = $state(100);
	let loaded = $state(false);

	function onWheel(e: WheelEvent) {
		if (!e.ctrlKey) return;
		e.preventDefault();
		const delta = e.deltaY < 0 ? 10 : -10;
		zoom = Math.min(400, Math.max(25, zoom + delta));
	}
</script>

<div class="flex-1 overflow-auto p-4 relative" onwheel={onWheel}>
	<img
		{src}
		{alt}
		style="width: {zoom}%; max-width: none; display: block; margin: 0 auto;"
		referrerpolicy="no-referrer"
		onload={() => (loaded = true)}
	/>
	{#if loaded}
		<div class="sticky bottom-2 flex justify-center pointer-events-none mt-4">
			<div
				class="pointer-events-auto flex items-center gap-1 px-3 py-1.5 bg-zinc-50 border border-zinc-300 text-zinc-700 shadow-sm"
			>
				<button
					onclick={() => (zoom = Math.max(zoom - 25, 25))}
					class="p-1 rounded-none hover:bg-zinc-200 cursor-pointer"
				>
					<MagnifyingGlassMinusIcon class="size-4" />
				</button>
				<span class="text-sm tabular-nums w-10 text-center">{zoom}%</span>
				<button
					onclick={() => (zoom = Math.min(zoom + 25, 400))}
					class="p-1 rounded-none hover:bg-zinc-200 cursor-pointer"
				>
					<MagnifyingGlassPlusIcon class="size-4" />
				</button>
				<div class="w-px h-4 bg-zinc-300 mx-1 shrink-0"></div>
				<button
					onclick={() => (zoom = 100)}
					class="text-sm px-2 py-1 rounded-none hover:bg-zinc-200 cursor-pointer"
				>
					Reset
				</button>
			</div>
		</div>
	{/if}
</div>
