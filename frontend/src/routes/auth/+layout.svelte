<script lang="ts">
	let { children } = $props();
</script>

<div
	class="flex flex-col lg:flex-row min-h-screen bg-zinc-100 p-2 items-center lg:items-stretch justify-center lg:justify-normal"
>
	<div class="invisible lg:visible lg:w-1/2 bg-zinc-100"></div>

	<div
		class="w-full lg:w-1/2 bg-zinc-50 rounded-none flex items-center justify-center border border-zinc-300 px-4 py-20"
	>
		{@render children()}
	</div>
</div>
