<script lang="ts">
	import { PUBLIC_API_BASE_URL } from '$env/static/public';
	import { invalidateAll } from '$app/navigation';
	import { Dialog } from 'bits-ui';
	import type { PageData } from './$types';
	import type { Resource } from '$lib/types';
	import ResourceView from '$lib/components/ResourceView.svelte';

	import TrashIcon from 'phosphor-svelte/lib/TrashIcon';
	import XIcon from 'phosphor-svelte/lib/XIcon';
	import CircleNotchIcon from 'phosphor-svelte/lib/CircleNotchIcon';

	let { data }: { data: PageData } = $props();
	let loading = $state<number | null>(null);
	let previewResource = $state<Resource | null>(null);
	let previewOpen = $state(false);

	async function openResource(resourceId: number) {
		try {
			const res = await fetch(`${PUBLIC_API_BASE_URL}/api/resources/${resourceId}`, {
				credentials: 'include'
			});
			if (res.ok) {
				previewResource = await res.json();
				previewOpen = true;
			}
		} catch (err) {
			console.error('Error fetching resource:', err);
		}
	}

	async function dismissReport(reportId: number) {
		loading = reportId;
		try {
			const res = await fetch(`${PUBLIC_API_BASE_URL}/api/admin/reports/${reportId}`, {
				method: 'DELETE',
				credentials: 'include'
			});
			if (res.ok) {
				await invalidateAll();
			}
		} finally {
			loading = null;
		}
	}

	async function deleteResource(resourceId: number) {
		if (!confirm('¿Eliminar este recurso? Esta acción no se puede deshacer.')) return;
		loading = resourceId;
		try {
			const res = await fetch(`${PUBLIC_API_BASE_URL}/api/admin/resources/${resourceId}`, {
				method: 'DELETE',
				credentials: 'include'
			});
			if (res.ok) {
				await invalidateAll();
			}
		} finally {
			loading = null;
		}
	}

	function timeAgo(dateStr: string): string {
		const diff = Date.now() - new Date(dateStr).getTime();
		const minutes = Math.floor(diff / 60000);
		if (minutes < 60) return `hace ${minutes}m`;
		const hours = Math.floor(minutes / 60);
		if (hours < 24) return `hace ${hours}h`;
		const days = Math.floor(hours / 24);
		return `hace ${days}d`;
	}
</script>

<div class="bg-zinc-100 min-h-screen px-4">
	<div class="max-w-5xl mx-auto pt-12">
		<div class="flex items-center gap-3 mb-8">
			<h1 class="text-3xl text-zinc-700">Administración</h1>
		</div>

		<div class="bg-zinc-50 border border-zinc-300">
			<div class="px-4 py-3 border-b border-zinc-300 bg-zinc-100">
				<h2 class="text-lg text-zinc-600">Reportes</h2>
			</div>

			{#if data.reports.length === 0}
				<div class="p-8 text-center text-zinc-500">No hay reportes pendientes.</div>
			{:else}
				<div
					class="hidden md:grid grid-cols-[1fr_1fr_2fr_auto] gap-4 px-4 py-2 border-b border-zinc-200 text-sm text-zinc-500 font-medium"
				>
					<span>Recurso</span>
					<span>Reportado por</span>
					<span>Motivo</span>
					<span>Acciones</span>
				</div>

				{#each data.reports as report (report.id)}
					<div
						class="grid md:grid-cols-[1fr_1fr_2fr_auto] gap-2 md:gap-4 px-4 py-3 border-b border-zinc-200 items-center text-sm"
					>
						<div>
							<button
								onclick={() => openResource(report.resourceId)}
								class="text-zinc-900 hover:underline font-medium cursor-pointer text-left"
							>
								{report.resourceTitle}
							</button>
							<span class="text-zinc-400 block text-xs">por @{report.ownerUsername}</span>
						</div>
						<div>
							<a href="/user/{report.reporterUsername}" class="text-zinc-600 hover:underline">
								@{report.reporterUsername}
							</a>
							<span class="text-zinc-400 block text-xs">{timeAgo(report.createdAt)}</span>
						</div>
						<div class="text-zinc-600">{report.reason}</div>
						<div class="flex gap-1">
							<button
								onclick={() => deleteResource(report.resourceId)}
								disabled={loading !== null}
								class="flex items-center gap-1 px-2 py-1 bg-red-200 text-red-700 hover:bg-red-100 transition-colors cursor-pointer disabled:opacity-50"
								title="Eliminar recurso"
							>
								{#if loading === report.resourceId}
									<CircleNotchIcon class="size-4 animate-spin" />
								{:else}
									<TrashIcon class="size-4" />
								{/if}
								<span class="hidden md:inline">Eliminar</span>
							</button>
							<button
								onclick={() => dismissReport(report.id)}
								disabled={loading !== null}
								class="flex items-center gap-1 px-2 py-1 bg-zinc-200 text-zinc-600 hover:bg-zinc-100 transition-colors cursor-pointer disabled:opacity-50"
								title="Descartar reporte"
							>
								{#if loading === report.id}
									<CircleNotchIcon class="size-4 animate-spin" />
								{:else}
									<XIcon class="size-4" />
								{/if}
								<span class="hidden md:inline">Descartar</span>
							</button>
						</div>
					</div>
				{/each}
			{/if}
		</div>
	</div>
</div>

<Dialog.Root
	bind:open={previewOpen}
	onOpenChange={(v) => {
		if (!v) previewResource = null;
	}}
>
	<Dialog.Portal>
		<Dialog.Overlay class="fixed inset-0 z-50 bg-black/30" />
		<Dialog.Content
			class="bg-zinc-50 border-zinc-300 outline-hidden fixed left-[50%] top-[50%] z-50 w-full max-w-[calc(100%-1rem)] md:max-w-[calc(100%-8rem)] h-[calc(100svh-1rem)] md:h-[calc(100svh-4rem)] translate-x-[-50%] translate-y-[-50%] border overflow-hidden"
		>
			{#if previewResource}
				<ResourceView resource={previewResource} currentUserId={data.me?.id} />
			{/if}
		</Dialog.Content>
	</Dialog.Portal>
</Dialog.Root>
