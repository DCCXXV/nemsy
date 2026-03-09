<script lang="ts">
	let { username, size = 'md' }: { username: string; size?: 'sm' | 'md' | 'lg' } = $props();

	const palette = [
		{ bg: 'bg-yellow-200', text: 'text-yellow-900' },
		{ bg: 'bg-blue-200', text: 'text-blue-900' },
		{ bg: 'bg-lime-200', text: 'text-lime-900' },
		{ bg: 'bg-violet-200', text: 'text-violet-900' },
		{ bg: 'bg-red-200', text: 'text-red-900' },
		{ bg: 'bg-orange-200', text: 'text-orange-900' }
	];

	function hashUsername(s: string): number {
		let h = 0;
		for (let i = 0; i < s.length; i++) {
			h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
		}
		return Math.abs(h);
	}

	const color = $derived(palette[hashUsername(username) % palette.length]);
	const letter = $derived(username ? username[0].toUpperCase() : '?');

	const sizeClass = $derived(
		size === 'sm' ? 'size-8 text-sm' : size === 'lg' ? 'size-14 text-2xl' : 'size-11 text-base'
	);
</script>

<div
	class="{color.bg} {color.text} {sizeClass} flex items-center justify-center font-semibold select-none shrink-0"
>
	{letter}
</div>
