export interface User {
	id: number;
	email: string;
	username: string;
	hd?: string;
	studyId?: number;
	studyName?: string;
	universityId?: number;
	universityName?: string;
	universityDomain?: string;
}

export interface University {
	id: number;
	name: string;
	domain: string;
}

export interface Study {
	id: number;
	name: string;
}

export interface Subject {
	id: number;
	name: string;
	year?: string;
	pinned?: boolean;
}

export interface ResourceFile {
	id: number;
	fileName: string;
	fileSize: number;
}

export interface Resource {
	id: number;
	title: string;
	description?: string;
	files: ResourceFile[];
	createdAt: string;
	downloadCount: number;
	owner?: {
		id: number;
		username: string;
		email: string;
	};
	subject?: {
		id: number;
		name: string;
	};
	study?: {
		id: number;
		name: string;
	};
	university?: {
		id: number;
		name: string;
	};
}
